#!/usr/bin/env bash
# Usage: tool/test/scripts/windows_vm.sh <command> [args]
#
# Throwaway Windows 11 VMs (dockur/windows: QEMU/KVM in a Docker container)
# on the Linux host, so nothing touches a real Windows installation. The VM is
# operated over SSH (as the admin user sheetopia, elevated) and its screen
# over VNC. tool/test/windows/ holds the scripts that run inside it.
#
#   golden                       install the golden test VM (Windows 11, SSH,
#                                loopMIDI, once, prereqs.sh)
#   golden-build                 the golden build VM: a copy of the test VM
#                                with MSVC, Git and Inno Setup
#   up <run>                     copy the golden disk and boot it
#   provision <run> [<release>]  up, fixtures to ~/e2e/fixtures, install the
#                                build under test (or the release dir, e.g.
#                                v0.8.0)
#   install <run> [<release>]    quit the app and install that release over
#                                it (data kept)
#   install-exe <run> <local .exe>     run an installer silently (all users)
#   launch <run> [--fake-github URL] [--env K=V]... [--zip] [--exe PATH]
#                                (re)start the app in the desktop session,
#                                stdout/stderr go to ~/e2e/app.log in the VM
#                                (--zip: ~/sheetopia-zip/sheetopia.exe)
#   quit <run>                   kill the app (use Alt+F4 via vnc to quit
#                                like a user)
#   snapshot <run> save|restore <name>
#                                app data and ~/Downloads to/from
#                                <run>/snapshots/ (quits the app), restore
#                                also closes Explorer and Edge windows, stops
#                                the MIDI device and resets the clock
#   clock <run> +15m|+2h|-1d|reset    set the VM's clock relative to the
#                                host's time
#   exec <run> -- cmd...         run a cmd.exe command line over SSH
#   sh <run> 'script'            run a PowerShell script over SSH (elevated,
#                                can't see or open windows)
#   desktop <run> 'script'       run a PowerShell script in the desktop
#                                session (unelevated, sees the windows)
#   winstate <run>               geometry and state of the app windows
#   midi <run> start [name] | send <hex bytes> | stop
#                                virtual MIDI device (loopMIDI driver)
#   push <run> <local path> <vm dir>   copy a file/dir into the VM
#   pull <run> <vm path> <local dir>   copy a file/dir out of the VM
#   vnc <run> <vnc action...>    the screen: screenshot/click/type/key/...
#                                (see harness/bin/vnc.dart)
#   down <run>                   remove the container and its disk
#
# Every command after `golden-build` takes `--vm <name>` right after the run
# to pick one of several VMs of a run (default "test"; "build" boots the
# golden build VM). VM paths may use / or \. State of a running VM is kept in
# <run>/env/windows-<name>.env, its disk in <run>/env/windows-<name>-disk/.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

CMD="${1:?usage: windows_vm.sh <command> [args]}"
shift

SSH_PORT=""
VNC=""
CONTAINER=""
HOME_WIN="C:\\Users\\$WINDOWS_USER"

vm_ssh() {
  # Only this key: sshd drops the connection after six refused keys, and an
  # SSH agent offers its own first.
  ssh -i "$WINDOWS_SSH_KEY" -p "$SSH_PORT" -o IdentitiesOnly=yes -o IdentityAgent=none \
    -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    -o LogLevel=ERROR -o ConnectTimeout=10 -o ServerAliveInterval=15 \
    "$WINDOWS_USER@127.0.0.1" "$@"
}

# Pushes a PowerShell script into C:\e2e\tmp and prints its VM path. The
# script deletes itself when it runs.
push_script() { # push_script <script text>
  local tmp name
  tmp="$(mktemp -d)"
  name="e2e-$RANDOM$RANDOM.ps1"
  {
    printf '\xef\xbb\xbf'
    printf '%s\r\n' 'Remove-Item -LiteralPath $PSCommandPath -ErrorAction SilentlyContinue' '$ProgressPreference = "SilentlyContinue"'
    printf '%s\r\n' "$1"
  } >"$tmp/$name"
  tar -C "$tmp" -cf - "$name" | vm_ssh 'tar -xf - -C C:/e2e/tmp'
  rm -rf "$tmp"
  echo "C:\\e2e\\tmp\\$name"
}

vm_ps() { # vm_ps <script text>: PowerShell over SSH
  vm_ssh "powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $(push_script "$1")"
}

vm_desktop() { # vm_desktop <script text> [--wait | --name <task>]
  local file
  file="$(push_script "$1")"
  shift
  case "${1:-}" in
    --wait) vm_ssh "powershell -NoProfile -ExecutionPolicy Bypass -File C:\\e2e\\windows\\desktop.ps1 -File $file -Wait" ;;
    --name) vm_ssh "powershell -NoProfile -ExecutionPolicy Bypass -File C:\\e2e\\windows\\desktop.ps1 -File $file -Name $2" ;;
    *) vm_ssh "powershell -NoProfile -ExecutionPolicy Bypass -File C:\\e2e\\windows\\desktop.ps1 -File $file" ;;
  esac
}

stop_app() { vm_ssh 'taskkill /F /T /IM sheetopia.exe >nul 2>&1 & exit 0' || true; }

# The disks belong to root (written by the container), so they are copied
# and deleted from a container too.
clone_disk() { # clone_disk <golden dir> <dest dir>
  mkdir -p "$2"
  docker run --rm --entrypoint sh -v "$1:/g:ro" -v "$2:/d" "$WINDOWS_IMAGE" \
    -c 'cp -a --reflink=auto --sparse=always /g/. /d/ && rm -f /d/*.iso'
}
remove_dir() { # remove_dir <dir>
  [ -d "$1" ] || return 0
  docker run --rm --entrypoint sh -v "$(dirname "$1"):/p" "$WINDOWS_IMAGE" -c "rm -rf '/p/$(basename "$1")'"
}

start_container() { # start_container <storage dir> <cpus> <memory GB> [docker args...]
  local storage="$1" cpus="$2" mem="$3"
  shift 3
  docker rm -f "$CONTAINER" >/dev/null 2>&1 || true
  docker run -d --name "$CONTAINER" --device /dev/kvm --device /dev/net/tun --cap-add NET_ADMIN --stop-timeout 120 \
    -e VERSION=11 -e RAM_SIZE="${mem}G" -e CPU_CORES="$cpus" -e DISK_SIZE=64G \
    -e USERNAME="$WINDOWS_USER" -e PASSWORD="$WINDOWS_PASSWORD" \
    -e LANGUAGE=en-US -e REGION=en-US -e KEYBOARD=en-US -e WIDTH=1280 -e HEIGHT=800 -e DISPLAY=vnc \
    -p 127.0.0.1::22 -p 127.0.0.1::5900 -v "$storage:/storage" "$@" "$WINDOWS_IMAGE" >/dev/null
  SSH_PORT="$(docker port "$CONTAINER" 22/tcp | head -1 | sed 's/.*://')"
  VNC="vnc://127.0.0.1:$(docker port "$CONTAINER" 5900/tcp | head -1 | sed 's/.*://')"
}

wait_ssh() { # wait_ssh <minutes>
  local i
  for ((i = 0; i < $1 * 6; i++)); do
    if vm_ssh 'exit 0' >/dev/null 2>&1; then return 0; fi
    [ "$(docker inspect -f '{{.State.Running}}' "$CONTAINER" 2>/dev/null)" = true ] ||
      die "the container $CONTAINER stopped, see docker logs $CONTAINER"
    sleep 10
  done
  die "no SSH in $CONTAINER after $1 min (VNC $VNC, docker logs $CONTAINER)"
}

push_helpers() {
  vm_ssh 'if not exist C:\e2e\tmp mkdir C:\e2e\tmp' >/dev/null
  tar -C "$E2E_DIR" -cf - windows | vm_ssh 'tar -xf - -C C:/e2e'
}

shutdown_container() {
  docker stop -t 150 "$CONTAINER" >/dev/null 2>&1 || true
  docker rm -f "$CONTAINER" >/dev/null 2>&1 || true
}

# Windows names its time zones itself, pick the one with the host's offsets
# in winter and summer.
set_clock_script() { # set_clock_script <epoch>
  local year jan jul
  year="$(date +%Y)"
  offset_min() { local z; z="$(date -d "$1" +%z)"; echo $(((${z:0:1}1) * (10#${z:1:2} * 60 + 10#${z:3:2}))); }
  jan="$(offset_min "$year-01-15 12:00")"
  jul="$(offset_min "$year-07-15 12:00")"
  cat <<EOF
\$tz = [TimeZoneInfo]::GetSystemTimeZones() | Where-Object {
  \$_.GetUtcOffset([datetime]::new($year, 1, 15, 12, 0, 0)).TotalMinutes -eq $jan -and
  \$_.GetUtcOffset([datetime]::new($year, 7, 15, 12, 0, 0)).TotalMinutes -eq $jul } | Select-Object -First 1
if (\$tz -and (Get-TimeZone).Id -ne \$tz.Id) { Set-TimeZone -Id \$tz.Id; [TimeZoneInfo]::ClearCachedData() }
Set-Date -Date ([DateTimeOffset]::FromUnixTimeSeconds($1).LocalDateTime) | Out-Null
Get-Date -Format 'yyyy-MM-dd HH:mm:ss zzz'
EOF
}

to_win() { local p="${1//\//\\}"; echo "${p%\\}"; }

if [ "$CMD" = golden ]; then
  if [ -f "$WINDOWS_GOLDEN.ready" ]; then
    log "golden VM $WINDOWS_GOLDEN exists, delete it and $WINDOWS_GOLDEN.ready to rebuild"
    exit 0
  fi
  mkdir -p "$WINDOWS_HOME"
  [ -f "$WINDOWS_SSH_KEY" ] || ssh-keygen -q -t ed25519 -N '' -C sheetopia-e2e -f "$WINDOWS_SSH_KEY"
  loopmidi="$WINDOWS_HOME/loopMIDISetup.exe"
  if [ ! -f "$loopmidi" ]; then
    tmp="$(mktemp -d)"
    if curl -fsSL --retry 3 -o "$tmp/loopmidi.zip" "$LOOPMIDI_URL" && unzip -q -o "$tmp/loopmidi.zip" -d "$tmp/x" &&
      [ -n "$(find "$tmp/x" -iname '*.exe' | head -1)" ]; then
      cp "$(find "$tmp/x" -iname '*.exe' | head -1)" "$loopmidi"
    else
      log "warning: downloading loopMIDI from $LOOPMIDI_URL failed, the MIDI tests will be blocked on Windows"
    fi
    rm -rf "$tmp"
  fi
  CONTAINER="sheetopia-e2e-windows-golden"
  oem=""
  if [ "$(docker inspect -f '{{.State.Running}}' "$CONTAINER" 2>/dev/null)" = true ]; then
    # An earlier golden run was interrupted, its install goes on.
    log "continuing with the running $CONTAINER"
    SSH_PORT="$(docker port "$CONTAINER" 22/tcp | head -1 | sed 's/.*://')"
    VNC="vnc://127.0.0.1:$(docker port "$CONTAINER" 5900/tcp | head -1 | sed 's/.*://')"
  else
    remove_dir "$WINDOWS_GOLDEN"
    oem="$(mktemp -d)"
    sed 's/\r*$/\r/' "$E2E_DIR/windows/install.bat" >"$oem/install.bat"
    cp "$E2E_DIR/windows/ssh.ps1" "$oem/"
    cp "$WINDOWS_SSH_KEY.pub" "$oem/e2e_key.pub"
    chmod -R a+rX "$oem"
    mkdir -p "$WINDOWS_GOLDEN"
    start_container "$WINDOWS_GOLDEN" 4 8 -v "$oem:/oem"
  fi
  log "installing Windows 11 in $CONTAINER (downloads ~8 GB, takes up to 1.5 h)."
  log "progress: docker logs -f $CONTAINER"
  log "screen, once the ISO is downloaded and the VM boots: SHEETOPIA_VNC=$VNC tool/test/scripts/tool.sh vnc screenshot /tmp/windows.png"
  wait_ssh 180
  log "provisioning the golden VM"
  push_helpers
  args=""
  if [ -f "$loopmidi" ]; then
    tar -C "$WINDOWS_HOME" -cf - "$(basename "$loopmidi")" | vm_ssh 'tar -xf - -C C:/e2e/tmp'
    args="-LoopMidi C:\\e2e\\tmp\\$(basename "$loopmidi")"
  fi
  vm_ssh "powershell -NoProfile -ExecutionPolicy Bypass -File C:\\e2e\\windows\\setup.ps1 $args"
  vm_ssh 'del /q C:\e2e\tmp\* >nul 2>&1 & exit 0'
  shutdown_container
  [ -z "$oem" ] || rm -rf "$oem"
  touch "$WINDOWS_GOLDEN.ready"
  log "golden VM ready: $WINDOWS_GOLDEN"
  exit 0
fi

if [ "$CMD" = golden-build ]; then
  [ -f "$WINDOWS_GOLDEN.ready" ] || die "build the golden test VM first (windows_vm.sh golden)"
  if [ -f "$WINDOWS_BUILD_GOLDEN.ready" ]; then
    log "golden build VM $WINDOWS_BUILD_GOLDEN exists, delete it and $WINDOWS_BUILD_GOLDEN.ready to rebuild"
    exit 0
  fi
  CONTAINER="sheetopia-e2e-windows-golden-build"
  if [ "$(docker inspect -f '{{.State.Running}}' "$CONTAINER" 2>/dev/null)" = true ]; then
    log "continuing with the running $CONTAINER"
    SSH_PORT="$(docker port "$CONTAINER" 22/tcp | head -1 | sed 's/.*://')"
    VNC="vnc://127.0.0.1:$(docker port "$CONTAINER" 5900/tcp | head -1 | sed 's/.*://')"
  else
    remove_dir "$WINDOWS_BUILD_GOLDEN"
    log "copying the golden VM"
    clone_disk "$WINDOWS_GOLDEN" "$WINDOWS_BUILD_GOLDEN"
    start_container "$WINDOWS_BUILD_GOLDEN" 4 8
  fi
  wait_ssh 20
  push_helpers
  log "installing the build tools (takes up to 30 min)"
  vm_ssh "powershell -NoProfile -ExecutionPolicy Bypass -File C:\\e2e\\windows\\build-tools.ps1 -VsUrl $VS_BUILDTOOLS_URL -GitUrl $GIT_WINDOWS_URL -InnoUrl $INNO_SETUP_URL"
  shutdown_container
  touch "$WINDOWS_BUILD_GOLDEN.ready"
  log "golden build VM ready: $WINDOWS_BUILD_GOLDEN"
  exit 0
fi

RUN="$(run_dir "${1:?run required}")"
shift
NAME="test"
if [ "${1:-}" = "--vm" ]; then NAME="${2:?--vm needs a name}"; shift 2; fi
RUN_ID="$(basename "$RUN")"
CONTAINER="sheetopia-e2e-$RUN_ID-windows-$NAME"
STATE="$RUN/env/windows-$NAME.env"
STORAGE="$RUN/env/windows-$NAME-disk"
export E2E_PLAN="$RUN/test-plan.yaml"
[ "${1:-}" = "--" ] && shift
if [ "$CMD" != up ] && [ "$CMD" != provision ] && [ "$CMD" != down ]; then
  [ -f "$STATE" ] || die "the Windows VM $NAME of this run is not up"
fi
if [ -f "$STATE" ]; then
  SSH_PORT="$(sed -n 's/^SSH_PORT=//p' "$STATE")"
  VNC="$(sed -n 's/^VNC=//p' "$STATE")"
fi

case "$CMD" in
  up)
    golden="$WINDOWS_GOLDEN"
    [ "$NAME" = build ] && golden="$WINDOWS_BUILD_GOLDEN"
    [ -f "$golden.ready" ] || die "no golden VM at $golden, run tool/test/scripts/prereqs.sh"
    mkdir -p "$RUN/env" "$RUN/logs"
    if [ ! -d "$STORAGE" ]; then
      log "copying the golden disk"
      clone_disk "$golden" "$STORAGE"
    fi
    cpus="$(plan get platforms.windows.vm.cpus 2>/dev/null || true)"
    mem="$(plan get platforms.windows.vm.memory_gb 2>/dev/null || true)"
    log "booting $CONTAINER"
    start_container "$STORAGE" "${cpus:-4}" "${mem:-8}"
    {
      echo "CONTAINER=$CONTAINER"
      echo "SSH_PORT=$SSH_PORT"
      echo "VNC=$VNC"
    } >"$STATE"
    wait_ssh 15
    push_helpers
    # SSH answers before the desktop session is up. Windows that start with
    # it (loopMIDI, OneDrive) would cover the app.
    vm_ps 'for ($i = 0; $i -lt 120 -and -not (Get-Process explorer -ErrorAction SilentlyContinue); $i++) { Start-Sleep 1 }
      Remove-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run", "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run" -Name loopMIDI, OneDrive -ErrorAction SilentlyContinue
      Start-Sleep 5
      Stop-Process -Name loopMIDI, OneDrive -Force -ErrorAction SilentlyContinue' >/dev/null
    sleep 5
    vm_ps "$(set_clock_script "$(date +%s)")" >/dev/null
    SHEETOPIA_VNC="$VNC" e2e_tool vnc screenshot "$RUN/logs/vnc-warmup-windows-$NAME.png" >/dev/null 2>&1 || true
    cat "$STATE"
    ;;
  provision)
    "$0" up "$RUN" --vm "$NAME" >/dev/null
    release="${1:-v$(jq -r .versions.current "$RUN/run.json")}"
    "$0" push "$RUN" --vm "$NAME" "$RUN/fixtures" "C:/Users/$WINDOWS_USER/e2e"
    "$0" install-exe "$RUN" --vm "$NAME" "$(ls "$RUN/releases/$release/"*windows-x86-64.exe | head -1)"
    ;;
  install)
    release="${1:-v$(jq -r .versions.current "$RUN/run.json")}"
    "$0" install-exe "$RUN" --vm "$NAME" "$(ls "$RUN/releases/$release/"*windows-x86-64.exe | head -1)"
    ;;
  install-exe)
    exe="${1:?local .exe required}"
    stop_app
    "$0" push "$RUN" --vm "$NAME" "$exe" "C:/Users/$WINDOWS_USER/Downloads"
    vm_ps "
\$p = Start-Process '$HOME_WIN\\Downloads\\$(basename "$exe")' -ArgumentList '/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART', '/ALLUSERS' -Wait -PassThru
if (\$p.ExitCode -ne 0) { Write-Error \"the installer failed with exit code \$(\$p.ExitCode)\"; exit 1 }
Get-ItemProperty 'HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\*', 'HKLM:\\SOFTWARE\\WOW6432Node\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\*', 'HKCU:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\*' -ErrorAction SilentlyContinue |
  Where-Object DisplayName -like 'Sheetopia*' | ForEach-Object DisplayVersion"
    ;;
  launch)
    sets=""
    exe='set "EXE=%ProgramFiles%\Sheetopia\sheetopia.exe"'$'\r\n''if not exist "%EXE%" set "EXE=%LOCALAPPDATA%\Programs\Sheetopia\sheetopia.exe"'
    while [ $# -gt 0 ]; do
      case "$1" in
        --fake-github) sets+="set \"SHEETOPIA_GITHUB_API_URL=$2\""$'\r\n'"set \"SHEETOPIA_GITHUB_WEB_URL=$2\""$'\r\n'; shift 2 ;;
        --env) sets+="set \"$2\""$'\r\n'; shift 2 ;;
        --zip) exe='set "EXE=%USERPROFILE%\sheetopia-zip\sheetopia.exe"'; shift ;;
        --exe) exe="set \"EXE=$(to_win "$2")\""; shift 2 ;;
        *) die "unknown launch option $1" ;;
      esac
    done
    stop_app
    tmp="$(mktemp -d)"
    printf '@echo off\r\n%s%s\r\ncd /d "%%USERPROFILE%%"\r\n"%%EXE%%" > "%%USERPROFILE%%\\e2e\\app.log" 2>&1\r\n' "$sets" "$exe" >"$tmp/launch.cmd"
    tar -C "$tmp" -cf - launch.cmd | vm_ssh 'tar -xf - -C C:/e2e/tmp'
    rm -rf "$tmp"
    vm_ssh 'powershell -NoProfile -ExecutionPolicy Bypass -File C:\e2e\windows\desktop.ps1 -File C:\e2e\tmp\launch.cmd -Name app'
    vm_ps 'for ($i = 0; $i -lt 30 -and -not (Get-Process sheetopia -ErrorAction SilentlyContinue); $i++) { Start-Sleep 1 }
      $p = Get-Process sheetopia -ErrorAction SilentlyContinue | Select-Object -First 1
      if (-not $p) { Write-Error "the app did not start, see ~/e2e/app.log and C:\e2e\tmp\e2e-app.out"; exit 1 }
      "started $($p.Path)"'
    ;;
  quit)
    stop_app
    ;;
  snapshot)
    action="${1:?save or restore}"
    file="$RUN/snapshots/windows-${2:?snapshot name required}.tar"
    stop_app
    case "$action" in
      save)
        mkdir -p "$RUN/snapshots"
        vm_ssh "cd /d $HOME_WIN && (if not exist AppData\\Roaming\\juho05\\Sheetopia mkdir AppData\\Roaming\\juho05\\Sheetopia) && tar -cf - AppData/Roaming/juho05/Sheetopia Downloads" >"$file.tmp"
        mv "$file.tmp" "$file"
        ;;
      restore)
        [ -f "$file" ] || die "no snapshot $file"
        vm_ps '$h = $env:USERPROFILE
          New-Item -ItemType File -Force C:\e2e\midi\stop | Out-Null
          Stop-Process -Name msedge -Force -ErrorAction SilentlyContinue
          Remove-Item -Recurse -Force "$h\AppData\Roaming\juho05\Sheetopia", "$h\sheetopia-zip" -ErrorAction SilentlyContinue
          Get-ChildItem "$h\Downloads" -Force | Remove-Item -Recurse -Force
          Start-Sleep 1
          Get-ScheduledTask -TaskName "e2e-*" -ErrorAction SilentlyContinue | Unregister-ScheduledTask -Confirm:$false
          Remove-Item C:\e2e\midi\* -Force -ErrorAction SilentlyContinue' >/dev/null
        vm_ssh "tar -xf - -C C:/Users/$WINDOWS_USER" <"$file"
        vm_desktop '(New-Object -ComObject Shell.Application).Windows() | ForEach-Object { $_.Quit() }' --wait >/dev/null || true
        "$0" clock "$RUN" --vm "$NAME" reset 2>/dev/null
        ;;
      *) die "snapshot save|restore <name>" ;;
    esac
    log "snapshot $action $2"
    ;;
  clock)
    target="$(clock_target "${1:-}")"
    log "VM clock: $(vm_ps "$(set_clock_script "$target")")"
    ;;
  exec)
    vm_ssh "$@"
    ;;
  sh)
    vm_ps "${1:?script required}"
    ;;
  desktop)
    vm_desktop "${1:?script required}" --wait
    ;;
  winstate)
    vm_ssh 'powershell -NoProfile -ExecutionPolicy Bypass -File C:\e2e\windows\desktop.ps1 -File C:\e2e\windows\winstate.ps1 -Wait'
    ;;
  midi)
    sub="${1:?start, send or stop}"
    shift
    case "$sub" in
      start)
        q="'"
        port="${1:-E2E Pedal}"
        port="${port//$q/$q$q}"
        vm_ps 'New-Item -ItemType File -Force C:\e2e\midi\stop | Out-Null
          for ($i = 0; $i -lt 20 -and (Test-Path C:\e2e\midi\port); $i++) { Start-Sleep -Milliseconds 250 }
          Remove-Item C:\e2e\midi\* -Force -ErrorAction SilentlyContinue' >/dev/null
        vm_desktop "& C:\\e2e\\windows\\midi.ps1 -Name '$port'" --name midi
        vm_ps 'for ($i = 0; $i -lt 60 -and -not (Test-Path C:\e2e\midi\port); $i++) { Start-Sleep -Milliseconds 250 }
          if (-not (Test-Path C:\e2e\midi\port)) { Get-Content C:\e2e\tmp\e2e-midi.out -ErrorAction SilentlyContinue; Write-Error "the MIDI device did not start"; exit 1 }
          # Windows MIDI Services only lists teVirtualMIDI ports that existed when midisrv started.
          Restart-Service midisrv -Force -ErrorAction Stop
          "MIDI device $(Get-Content C:\e2e\midi\port) is up"'
        ;;
      send)
        [ $# -gt 0 ] || die "midi send <hex bytes>"
        [[ "$*" =~ ^[0-9A-Fa-f\ ]+$ ]] || die "midi send takes hex bytes like 90 3C 7F"
        vm_ps "if (-not (Test-Path C:\\e2e\\midi\\port)) { Write-Error 'no MIDI device, run midi start first'; exit 1 }
          \$f = 'C:\\e2e\\midi\\$(date +%s%N).msg'
          Set-Content \$f '$*'
          for (\$i = 0; \$i -lt 40 -and (Test-Path \$f); \$i++) { Start-Sleep -Milliseconds 50 }
          if (Test-Path \$f) { Write-Error 'the MIDI device did not send it'; exit 1 }
          'sent $*'"
        ;;
      stop)
        vm_ps 'New-Item -ItemType File -Force C:\e2e\midi\stop | Out-Null
          for ($i = 0; $i -lt 20 -and (Test-Path C:\e2e\midi\port); $i++) { Start-Sleep -Milliseconds 250 }
          "MIDI device stopped"'
        ;;
      *) die "midi start|send|stop" ;;
    esac
    ;;
  push)
    src="${1:?local path required}" dest="$(to_win "${2:?vm dir required}")"
    vm_ssh "if not exist \"$dest\" mkdir \"$dest\""
    tar -C "$(dirname "$src")" -cf - "$(basename "$src")" | vm_ssh "tar -xf - -C \"${dest//\\//}\""
    ;;
  pull)
    src="$(to_win "${1:?vm path required}")" dest="${2:?local dir required}"
    mkdir -p "$dest"
    vm_ssh "tar -C \"$(dirname "${src//\\//}")\" -cf - \"$(basename "${src//\\//}")\"" | tar -xf - -C "$dest"
    ;;
  vnc)
    SHEETOPIA_VNC="$VNC" e2e_tool vnc "$@"
    ;;
  down)
    docker rm -f "$CONTAINER" >/dev/null 2>&1 || true
    remove_dir "$STORAGE"
    rm -f "$STATE"
    log "deleted $CONTAINER"
    ;;
  *)
    die "unknown command $CMD"
    ;;
esac
