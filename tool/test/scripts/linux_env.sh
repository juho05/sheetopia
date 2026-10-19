#!/usr/bin/env bash
# Usage: tool/test/scripts/linux_env.sh <command> <run> [args]
#
# Throwaway Linux desktops (Docker container, Ubuntu 24.04 + Xfce on a VNC
# display, see tool/test/linux/) for testing the Linux builds without touching
# the host's desktop or its Sheetopia installation.
#
#   image                         build the desktop image (once, prereqs.sh)
#   up <run>                      start the desktop
#   provision <run> [<release>]   up, fixtures to ~/e2e/fixtures, the AppImage
#                                 of the build under test (or the release dir,
#                                 e.g. v0.7.0) to ~/Downloads
#   app <run> [--env K=V]... [--integration] [--targz]
#                                 (re)start the installed release build: the
#                                 integrated AppImage, else the newest one in
#                                 ~/Downloads (--targz: ~/sheetopia-targz).
#                                 Suppresses the integration prompt unless
#                                 --integration
#   snapshot <run> save|restore <name>
#                                 app data, AppImage locations and ~/Downloads
#                                 to/from <run>/snapshots/ (stops the app),
#                                 restore also resets the desktop theme,
#                                 ~/sheetopia-targz and the opened URLs log
#   winstate <run>                geometry and _NET_WM_STATE of the app window
#   exec <run> -- cmd...          run a command as the desktop user
#   sh <run> 'script'             run bash inside the desktop session
#                                 (DISPLAY, session bus, keyring)
#   push <run> <local path> <dir> copy into the container (as the user)
#   pull <run> <path> <local dir> copy out of the container
#   vnc <run> <vnc action...>     the screen: screenshot/click/type/key/...
#   driver <run> [--env K=V]...   start the E2E profile build
#                                 (builds/current/linux-e2e) and print the VM
#                                 service URL for `tool.sh drive`
#   down <run>                    remove the container
#
# From inside the container the host is host.docker.internal. The ALSA
# sequencer and the host's VirMIDI cards are passed in for MIDI (prereqs.sh
# loads snd-virmidi), no other sound devices. State: <run>/env/linux.env.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

CMD="${1:?usage: linux_env.sh <command> <run> [args]}"
shift

image_hash() { (cd "$E2E_DIR/linux" && cat $(ls | sort) | sha256 | cut -c1-16); }

if [ "$CMD" = "image" ]; then
  docker build --label "e2e.hash=$(image_hash)" -t "$LINUX_IMAGE" "$E2E_DIR/linux"
  exit 0
fi

RUN="$(run_dir "${1:?run required}")"
shift
[ "${1:-}" = "--" ] && shift
STATE="$RUN/env/linux.env"
NAME="sheetopia-e2e-$(basename "$RUN")"
if [ "$CMD" != "up" ] && [ "$CMD" != "provision" ]; then
  [ -f "$STATE" ] || die "the Linux desktop of this run is not up"
  # shellcheck disable=SC1090
  source "$STATE"
fi

in_session() { # runs bash in the desktop session as the user
  docker exec -i -u "$LINUX_USER" "$NAME" bash -c 'source ~/.e2e-session.env 2>/dev/null; cd ~; bash -s'
}

stop_app() {
  docker exec -u "$LINUX_USER" "$NAME" bash -c 'pkill -x sheetopia; pkill -x AppRun; pkill -f "[.]AppImage|[/]local/bin/sheetopia"; pkill -x thunar; sleep 1' || true
}

# Relative to the user's home. Integration moves the AppImage out of
# ~/Downloads, so both locations belong to the state.
SNAPSHOT_PATHS=".local/share/$APP_ID .local/bin/sheetopia .local/share/applications/$APP_ID.desktop Downloads"
case "$CMD" in
  up)
    mkdir -p "$RUN/env" "$RUN/logs"
    # Rebuild when tool/test/linux changed since the image was built.
    built="$(docker image inspect -f '{{index .Config.Labels "e2e.hash"}}' "$LINUX_IMAGE" 2>/dev/null || true)"
    [ "$built" = "$(image_hash)" ] || "$0" image >&2
    docker rm -f "$NAME" >/dev/null 2>&1 || true
    devices=(--device /dev/fuse)
    if [ -e /dev/snd/seq ]; then
      # Only the sequencer and the VirMIDI cards, the host's real MIDI hardware
      # must not show up in the app.
      devices+=(--device /dev/snd/seq --group-add "$(stat -c %g /dev/snd/seq)")
      [ -e /dev/snd/timer ] && devices+=(--device /dev/snd/timer)
      for card in $(awk '/\[VirMIDI/ {print $1}' /proc/asound/cards 2>/dev/null); do
        for node in /dev/snd/controlC"$card" /dev/snd/midiC"$card"D*; do
          [ -e "$node" ] && devices+=(--device "$node")
        done
      done
    fi
    # FUSE for AppImages needs SYS_ADMIN and no AppArmor confinement.
    docker run -d --name "$NAME" --hostname sheetopia-e2e \
      --cap-add SYS_ADMIN --security-opt apparmor=unconfined "${devices[@]}" \
      --shm-size 1g -e TZ="$(host_timezone)" \
      --add-host host.docker.internal:host-gateway \
      -p 127.0.0.1::5901 -p 127.0.0.1::18181 \
      "$LINUX_IMAGE" >/dev/null
    for _ in $(seq 1 60); do
      docker exec "$NAME" test -f /home/$LINUX_USER/.e2e-desktop-ready 2>/dev/null && break
      sleep 1
    done
    sleep 3 # let Xfce draw the desktop
    vnc_port="$(docker port "$NAME" 5901/tcp | head -1 | sed 's/.*://')"
    driver_port="$(docker port "$NAME" 18181/tcp | head -1 | sed 's/.*://')"
    {
      echo "CONTAINER=$NAME"
      echo "VNC=vnc://127.0.0.1:$vnc_port"
      echo "DRIVER_PORT=$driver_port"
    } >"$STATE"
    cat "$STATE"
    ;;
  provision)
    "$0" up "$RUN" >/dev/null
    # shellcheck disable=SC1090
    source "$STATE"
    release="${1:-v$(jq -r .versions.current "$RUN/run.json")}"
    appimage="$(ls "$RUN/releases/$release/"*.AppImage | head -1)"
    "$0" push "$RUN" "$RUN/fixtures" /home/$LINUX_USER/e2e
    "$0" push "$RUN" "$appimage" /home/$LINUX_USER/Downloads
    "$0" exec "$RUN" -- chmod +x "/home/$LINUX_USER/Downloads/$(basename "$appimage")"
    log "provisioned with $(basename "$appimage")"
    ;;
  app)
    envs=" SHEETOPIA_DISABLE_APPIMAGE_INTEGRATION=1"
    bin='$(if [ -x ~/.local/bin/sheetopia ]; then echo ~/.local/bin/sheetopia; else ls -t ~/Downloads/*.AppImage | head -1; fi)'
    while [ $# -gt 0 ]; do
      case "$1" in
        --env) envs+=" $(printf '%q' "$2")"; shift 2 ;;
        --integration) envs="${envs/ SHEETOPIA_DISABLE_APPIMAGE_INTEGRATION=1/}"; shift ;;
        --targz) bin='~/sheetopia-targz/sheetopia'; shift ;;
        *) die "unknown app option $1" ;;
      esac
    done
    stop_app
    printf '%s\n' "bin=$bin; nohup env$envs \"\$bin\" >~/e2e/app.log 2>&1 & echo \"started \$bin\"" | in_session
    ;;
  snapshot)
    action="${1:?save or restore}"
    file="$RUN/snapshots/linux-${2:?snapshot name required}.tar"
    stop_app
    case "$action" in
      save)
        mkdir -p "$RUN/snapshots"
        docker exec -u "$LINUX_USER" "$NAME" bash -c "cd ~ && tar -cf - \$(ls -d $SNAPSHOT_PATHS 2>/dev/null)" >"$file.tmp"
        mv "$file.tmp" "$file"
        ;;
      restore)
        [ -f "$file" ] || die "no snapshot $file"
        docker exec -u "$LINUX_USER" "$NAME" bash -c "cd ~ && rm -rf $SNAPSHOT_PATHS"
        docker exec -i -u "$LINUX_USER" "$NAME" bash -c 'cd ~ && tar -xf -' <"$file"
        # Desktop state earlier tests may have changed, outside the snapshot.
        printf '%s\n' 'rm -rf ~/sheetopia-targz ~/e2e/opened-urls.log
          xfconf-query -c xsettings -p /Net/ThemeName -r 2>/dev/null || true
          gsettings reset org.gnome.desktop.interface color-scheme 2>/dev/null || true' | in_session
        ;;
      *) die "snapshot save|restore <name>" ;;
    esac
    log "snapshot $action $2"
    ;;
  exec)
    docker exec -u "$LINUX_USER" "$NAME" "$@"
    ;;
  sh)
    printf '%s\n' "${1:?script required}" | in_session
    ;;
  winstate)
    printf '%s\n' 'for id in $(xdotool search --class sheetopia 2>/dev/null); do
      eval "$(xdotool getwindowgeometry --shell "$id")"
      [ "$WIDTH" -lt 50 ] && continue
      echo "window $id ${WIDTH}x${HEIGHT}+${X}+${Y} $(xprop -id "$id" _NET_WM_STATE | sed "s/.*= //;s/_NET_WM_STATE_//g")"
    done
    xdotool search --class sheetopia >/dev/null 2>&1 || echo "no Sheetopia window"' | in_session
    ;;
  push)
    src="${1:?local path required}" dest="${2:?container dir required}"
    docker exec -u "$LINUX_USER" "$NAME" mkdir -p "$dest"
    tar -C "$(dirname "$src")" -cf - "$(basename "$src")" | docker exec -i -u "$LINUX_USER" "$NAME" tar -xf - -C "$dest"
    ;;
  pull)
    src="${1:?container path required}" dest="${2:?local dir required}"
    mkdir -p "$dest"
    docker exec -u "$LINUX_USER" "$NAME" tar -C "$(dirname "$src")" -cf - "$(basename "$src")" | tar -xf - -C "$dest"
    ;;
  vnc)
    SHEETOPIA_VNC="$VNC" e2e_tool vnc "$@"
    ;;
  driver)
    bundle="$RUN/builds/current/linux-e2e"
    [ -x "$bundle/sheetopia" ] || die "no E2E build at $bundle, run build.sh --only e2e"
    envs=""
    while [ $# -gt 0 ]; do
      case "$1" in
        --env) envs+=" $(printf '%q' "$2")"; shift 2 ;;
        *) die "unknown driver option $1" ;;
      esac
    done
    stop_app
    "$0" exec "$RUN" -- bash -c 'pkill -x socat; rm -rf ~/e2e/linux-e2e' || true
    "$0" push "$RUN" "$bundle" /home/$LINUX_USER/e2e
    printf '%s\n' "nohup env$envs ~/e2e/linux-e2e/sheetopia >~/e2e/app.log 2>&1 &" | in_session
    url=""
    for _ in $(seq 1 60); do
      url="$("$0" exec "$RUN" -- bash -c "grep -o 'http://127.0.0.1:[0-9]*/[^ ]*/' ~/e2e/app.log | tail -1" || true)"
      [ -n "$url" ] && break
      sleep 1
    done
    [ -n "$url" ] || die "the E2E build did not print a VM service URL, see ~/e2e/app.log in the container"
    port="$(sed -E 's|http://127.0.0.1:([0-9]+)/.*|\1|' <<<"$url")"
    # The VM service only listens on the container's loopback, expose it.
    docker exec -d -u "$LINUX_USER" "$NAME" socat TCP-LISTEN:18181,fork,reuseaddr "TCP:127.0.0.1:$port"
    url="${url/127.0.0.1:$port/127.0.0.1:$DRIVER_PORT}"
    sed_i '/^DRIVER_URL=/d' "$STATE"
    echo "DRIVER_URL=$url" >>"$STATE"
    echo "$url"
    ;;
  down)
    docker rm -f "$NAME" >/dev/null 2>&1 || true
    rm -f "$STATE"
    log "removed the Linux desktop"
    ;;
  *)
    die "unknown command $CMD"
    ;;
esac
