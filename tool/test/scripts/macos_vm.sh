#!/usr/bin/env bash
# Usage: tool/test/scripts/macos_vm.sh <command> [args]
#
# Throwaway macOS VMs (tart) for testing, so nothing touches the host's own
# Sheetopia installation.
#
#   golden                       build the golden test VM from MACOS_SOURCE_IMAGE
#   up <run>                     clone the golden image and boot it
#   provision <run> [<release>]  up, fixtures to ~/e2e/fixtures, install the
#                                build under test (or the release dir, e.g.
#                                v0.7.0)
#   clock <run> +15m|+2h|-1d|reset    set the VM's clock relative to the
#                                host's time
#   snapshot <run> save|restore <name>
#                                app data and preferences to/from
#                                <run>/snapshots/ (quits the app)
#   exec <run> -- cmd...         run a command in the VM (as admin, in the
#                                GUI session)
#   sh <run> 'script'            run a bash script in the VM
#   push <run> <local path> <vm dir>   copy a file/dir into the VM
#   pull <run> <vm path> <local dir>   copy a file/dir out of the VM
#   vnc <run> <vnc action...>    the screen: screenshot/click/type/key/...
#                                (see harness/bin/vnc.dart)
#   ip <run>
#   install-dmg <run> <local .dmg>     install like a user: mount, copy the
#                                      app to /Applications, unmount
#   launch <run> [--fake-github URL] [--app PATH] [--env K=V]...
#                                (re)start the app, stdout/stderr go to
#                                ~/e2e/app.log in the VM
#   quit <run>                   terminate the app (SIGTERM; use Cmd+Q via vnc
#                                to quit like a user)
#   down <run>                   stop and delete the VM
#
# Every command after `golden` takes `--vm <name>` right after the run to pick
# one of several VMs of a run (default "test").
#
# State of a running VM is kept in <run>/env/macos-<name>.env.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

CMD="${1:?usage: macos_vm.sh <command> [args]}"
shift

vm_exec() { tart exec "$VM" "$@"; }
vm_exec_stdin() { tart exec -i "$VM" "$@"; } # streams stdin into the command

wait_for_agent() {
  local vm="$1"
  for _ in $(seq 1 120); do
    if tart exec "$vm" true >/dev/null 2>&1; then return 0; fi
    sleep 5
  done
  die "VM $vm did not come up (no guest agent after 10 min)"
}

launchd_label() { echo "dev.sheetopia.e2e.$1"; }

start_vm() { # start_vm <vm> <log file>
  local vm="$1" logfile="$2"
  # Run under launchd so the VM doesn't die with the shell (or agent tool
  # call) that started it.
  launchctl remove "$(launchd_label "$vm")" 2>/dev/null || true
  : >"$logfile"
  launchctl submit -l "$(launchd_label "$vm")" -o "$logfile" -e "$logfile" -- \
    "$(command -v tart)" run --no-graphics --vnc-experimental "$vm"
  for _ in $(seq 1 60); do
    if grep -qo 'vnc://[^ ]*' "$logfile" 2>/dev/null; then break; fi
    sleep 2
  done
  wait_for_agent "$vm"
}

if [ "$CMD" = "golden" ]; then
  if tart list --quiet --source local | grep -qx "$MACOS_GOLDEN_VM"; then
    log "golden VM $MACOS_GOLDEN_VM exists, delete it first to rebuild"
    exit 0
  fi
  log "cloning $MACOS_SOURCE_IMAGE (downloads ~26 GB)"
  tart clone "$MACOS_SOURCE_IMAGE" "$MACOS_GOLDEN_VM"
  tart set "$MACOS_GOLDEN_VM" --cpu 4 --memory 8192 --display 1440x900
  tmp="$(mktemp -d)"
  start_vm "$MACOS_GOLDEN_VM" "$tmp/tart.log"
  VM="$MACOS_GOLDEN_VM"
  log "provisioning the golden VM"
  vm_exec bash -lc '
    set -euo pipefail
    # Never sleep, lock or show the screen saver while an agent drives it.
    sudo pmset -a sleep 0 displaysleep 0 disksleep 0
    defaults -currentHost write com.apple.screensaver idleTime 0
    sudo defaults write /Library/Preferences/com.apple.screensaver loginWindowIdleTime 0
    # No "reopen windows" and crash dialogs getting in the way.
    defaults write com.apple.loginwindow TALLogoutSavesState -bool false
    defaults write com.apple.CrashReporter DialogType none
    mkdir -p ~/bin ~/e2e
  '
  tar -C "$E2E_BIN" -cf - sendmidi | vm_exec_stdin tar -xf - -C /Users/$MACOS_VM_USER/bin
  # Shut down cleanly so everything written above reaches the disk image.
  launchctl remove "$(launchd_label "$MACOS_GOLDEN_VM")" 2>/dev/null || true
  vm_exec sync || true
  vm_exec sudo shutdown -h now >/dev/null 2>&1 || true
  for _ in $(seq 1 60); do
    tart list --source local | grep -E "^local +$MACOS_GOLDEN_VM " | grep -q stopped && break
    sleep 2
  done
  tart stop "$MACOS_GOLDEN_VM" 2>/dev/null || true
  rm -rf "$tmp"
  # The downloaded image is only needed to rebuild the golden VM.
  tart prune --entries=caches --older-than=0 >/dev/null 2>&1 || true
  log "golden VM ready: $MACOS_GOLDEN_VM"
  exit 0
fi

RUN="$(run_dir "${1:?run required}")"
shift
NAME="test"
if [ "${1:-}" = "--vm" ]; then NAME="${2:?--vm needs a name}"; shift 2; fi
RUN_ID="$(basename "$RUN")"
VM="sheetopia-e2e-$RUN_ID-$NAME"
STATE="$RUN/env/macos-$NAME.env"
export E2E_PLAN="$RUN/test-plan.yaml"
[ "${1:-}" = "--" ] && shift

case "$CMD" in
  up)
    mkdir -p "$RUN/env" "$RUN/logs"
    if ! tart list --quiet --source local | grep -qx "$VM"; then
      tart clone "$MACOS_GOLDEN_VM" "$VM"
    fi
    cpus="$(plan get platforms.macos.vm.cpus)"
    mem="$(plan get platforms.macos.vm.memory_gb)"
    tart set "$VM" --cpu "${cpus:-4}" --memory "$(((${mem:-8}) * 1024))"
    log "booting $VM"
    start_vm "$VM" "$RUN/logs/tart-$NAME.log"
    # The guest agent answers before the GUI session is up; wait for the Dock.
    for _ in $(seq 1 60); do
      vm_exec pgrep -x Dock >/dev/null 2>&1 && break
      sleep 2
    done
    sleep 5
    # The VNC server's first frame is blank, take it once here.
    SHEETOPIA_VNC="$(grep -o 'vnc://[^ ]*' "$RUN/logs/tart-$NAME.log" | head -1)" \
      e2e_tool vnc screenshot "$RUN/logs/vnc-warmup-$NAME.png" >/dev/null 2>&1 || true
    # Same time zone as the host so the demo library's "today" matches.
    tz="$(host_timezone)"
    vm_exec sudo systemsetup -settimezone "$tz" >/dev/null 2>&1 || true
    # Cloned VMs resume with the golden image's clock, set it to the host's.
    vm_exec sudo date -u "$(date -u +%m%d%H%M%Y.%S)" >/dev/null 2>&1 || true
    {
      echo "VM=$VM"
      echo "VNC=$(grep -o 'vnc://[^ ]*' "$RUN/logs/tart-$NAME.log" | head -1)"
      echo "IP=$(tart ip "$VM")"
    } >"$STATE"
    cat "$STATE"
    ;;
  provision)
    "$0" up "$RUN" --vm "$NAME" >/dev/null
    release="${1:-v$(jq -r .versions.current "$RUN/run.json")}"
    "$0" push "$RUN" --vm "$NAME" "$RUN/fixtures" /Users/$MACOS_VM_USER/e2e
    "$0" install-dmg "$RUN" --vm "$NAME" "$(ls "$RUN/releases/$release/"*.dmg | head -1)"
    ;;
  snapshot)
    action="${1:?save or restore}"
    file="$RUN/snapshots/macos-${2:?snapshot name required}.tar"
    vm_exec pkill -TERM -x Sheetopia >/dev/null 2>&1 || true
    sleep 2
    # cfprefsd caches preferences, so they go through defaults.
    case "$action" in
      save)
        mkdir -p "$RUN/snapshots"
        vm_exec bash -lc "cd ~ && rm -f e2e-prefs.plist && (defaults export $APP_ID e2e-prefs.plist 2>/dev/null || true)
          set --
          [ -e 'Library/Application Support/$APP_ID' ] && set -- \"\$@\" 'Library/Application Support/$APP_ID'
          [ -f e2e-prefs.plist ] && set -- \"\$@\" e2e-prefs.plist
          tar -cf - \"\$@\"" >"$file.tmp"
        mv "$file.tmp" "$file"
        ;;
      restore)
        [ -f "$file" ] || die "no snapshot $file"
        vm_exec bash -lc "cd ~ && rm -rf 'Library/Application Support/$APP_ID' e2e-prefs.plist"
        vm_exec_stdin bash -lc 'cd ~ && tar -xf -' <"$file"
        vm_exec bash -lc "cd ~ && if [ -f e2e-prefs.plist ]; then defaults import $APP_ID e2e-prefs.plist; else defaults delete $APP_ID 2>/dev/null || true; fi"
        "$0" clock "$RUN" --vm "$NAME" reset 2>/dev/null
        ;;
      *) die "snapshot save|restore <name>" ;;
    esac
    log "snapshot $action $2"
    ;;
  clock)
    target="$(clock_target "${1:-}")"
    if [ "$1" = reset ]; then network=on; else network=off; fi
    vm_exec sudo systemsetup -setusingnetworktime "$network" >/dev/null 2>&1 || true
    vm_exec sudo date -u "$(date -u -r "$target" +%m%d%H%M%Y.%S)" >/dev/null
    log "VM clock: $(vm_exec date)"
    ;;
  exec)
    vm_exec "$@"
    ;;
  sh)
    vm_exec bash -lc "${1:?script required}"
    ;;
  push)
    src="${1:?local path required}" dest="${2:?vm dir required}"
    vm_exec mkdir -p "$dest"
    tar -C "$(dirname "$src")" -cf - "$(basename "$src")" | vm_exec_stdin tar -xf - -C "$dest"
    ;;
  pull)
    src="${1:?vm path required}" dest="${2:?local dir required}"
    mkdir -p "$dest"
    vm_exec tar -C "$(dirname "$src")" -cf - "$(basename "$src")" | tar -xf - -C "$dest"
    ;;
  vnc)
    [ -f "$STATE" ] || die "VM $NAME is not up"
    SHEETOPIA_VNC="$(sed -n 's/^VNC=//p' "$STATE")" SHEETOPIA_VNC_KEYMAP=apple e2e_tool vnc "$@"
    ;;
  ip)
    tart ip "$VM"
    ;;
  install-dmg)
    dmg="${1:?local .dmg required}"
    vm_exec mkdir -p /Users/$MACOS_VM_USER/Downloads
    tar -C "$(dirname "$dmg")" -cf - "$(basename "$dmg")" | vm_exec_stdin tar -xf - -C /Users/$MACOS_VM_USER/Downloads
    vm_exec bash -lc "
      set -euo pipefail
      mnt=\$(mktemp -d)
      hdiutil attach -nobrowse -quiet -mountpoint \"\$mnt\" ~/Downloads/'$(basename "$dmg")'
      rm -rf /Applications/Sheetopia.app
      ditto \"\$mnt/Sheetopia.app\" /Applications/Sheetopia.app
      hdiutil detach -quiet \"\$mnt\"
      /usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' /Applications/Sheetopia.app/Contents/Info.plist
    "
    ;;
  launch)
    app=/Applications/Sheetopia.app
    envs=()
    while [ $# -gt 0 ]; do
      case "$1" in
        --fake-github) envs+=(--env "SHEETOPIA_GITHUB_API_URL=$2" --env "SHEETOPIA_GITHUB_WEB_URL=$2"); shift 2 ;;
        --app) app="$2"; shift 2 ;;
        --env) envs+=(--env "$2"); shift 2 ;;
        *) die "unknown launch option $1" ;;
      esac
    done
    vm_exec pkill -TERM -x Sheetopia >/dev/null 2>&1 || true
    sleep 2
    vm_exec open -n --stdout /Users/$MACOS_VM_USER/e2e/app.log --stderr /Users/$MACOS_VM_USER/e2e/app.log \
      ${envs[@]+"${envs[@]}"} "$app"
    log "launched $app"
    ;;
  quit)
    vm_exec pkill -TERM -x Sheetopia >/dev/null 2>&1 || true
    ;;
  down)
    launchctl remove "$(launchd_label "$VM")" 2>/dev/null || true
    tart stop "$VM" >/dev/null 2>&1 || true
    tart delete "$VM" >/dev/null 2>&1 || true
    rm -f "$STATE"
    log "deleted $VM"
    ;;
  *)
    die "unknown command $CMD"
    ;;
esac
