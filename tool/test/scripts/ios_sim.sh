#!/usr/bin/env bash
# Usage: tool/test/scripts/ios_sim.sh <command> <run> [args]
#
# A throwaway iOS simulator per run (never one of the host's own simulators).
#
#   up <run>                       create and boot (device type from the plan's
#                                  platforms.ios.devices.<sim>)
#   provision <run>                up and install the simulator build under test
#   snapshot <run> save|restore <name>
#                                  the app's data container to/from
#                                  <run>/snapshots/ (terminates the app)
#   install <run> <Runner.app>     install the app
#   launch <run> | terminate <run>
#   axe <run> <axe args...>        input and inspection: tap -x -y, swipe,
#                                  type, describe-ui, button home, ... (points)
#   screenshot <run> <file.png>
#   files <run> <file>...          put files into Files > On My iPhone
#   open-url <run> <url>
#   simctl <run> <simctl args...>  any simctl command, <udid> is appended
#                                  after the subcommand
#   down <run>                     shut down and delete
#
# Every command takes `--sim phone|tablet` right after the run to pick the
# simulator (default phone; tablet for iPad-only behaviour like Split View
# drag and drop). State: <run>/env/ios-<sim>.env.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

CMD="${1:?usage: ios_sim.sh <command> <run> [args]}"
RUN="$(run_dir "${2:?run required}")"
shift 2
SIM=phone
if [ "${1:-}" = "--sim" ]; then SIM="${2:?--sim needs phone or tablet}"; shift 2; fi
STATE="$RUN/env/ios-$SIM.env"
export E2E_PLAN="$RUN/test-plan.yaml"
if [ "$CMD" != "up" ] && [ "$CMD" != "provision" ]; then
  [ -f "$STATE" ] || die "the simulator of this run is not up"
  # shellcheck disable=SC1090
  source "$STATE"
fi

case "$CMD" in
  up)
    mkdir -p "$RUN/env"
    type="$(plan get "platforms.ios.devices.$SIM")"
    if [ -z "$type" ]; then
      if [ "$SIM" = tablet ]; then type="${IOS_DEVICE_TYPES[1]}"; else type="${IOS_DEVICE_TYPES[0]}"; fi
    fi
    runtime="$(xcrun simctl list runtimes available -j | jq -r '[.runtimes[] | select(.platform == "iOS")] | sort_by(.version) | last | .identifier')"
    UDID="$(xcrun simctl create "sheetopia-e2e-$(basename "$RUN")-$SIM" "$type" "$runtime")"
    echo "UDID=$UDID" >"$STATE"
    xcrun simctl boot "$UDID"
    xcrun simctl bootstatus "$UDID" -b >/dev/null
    # axe needs a moment after the first boot before its automation session
    # works.
    for _ in $(seq 1 12); do
      axe describe-ui --udid "$UDID" >/dev/null 2>&1 && break
      sleep 5
    done
    cat "$STATE"
    ;;
  provision)
    "$0" up "$RUN" --sim "$SIM" >/dev/null
    "$0" install "$RUN" --sim "$SIM" "$RUN/builds/current/ios/Runner.app"
    ;;
  snapshot)
    action="${1:?save or restore}"
    file="$RUN/snapshots/ios-$SIM-${2:?snapshot name required}.tar"
    xcrun simctl terminate "$UDID" "$APP_ID" >/dev/null 2>&1 || true
    container="$(xcrun simctl get_app_container "$UDID" "$APP_ID" data)"
    case "$action" in
      save)
        mkdir -p "$RUN/snapshots"
        tar -C "$container" -cf "$file.tmp" Documents Library
        mv "$file.tmp" "$file"
        ;;
      restore)
        [ -f "$file" ] || die "no snapshot $file"
        rm -rf "$container/Documents" "$container/Library"
        tar -C "$container" -xf "$file"
        # Preferences are cached outside the container.
        xcrun simctl spawn "$UDID" killall cfprefsd >/dev/null 2>&1 || true
        ;;
      *) die "snapshot save|restore <name>" ;;
    esac
    log "snapshot $action $2"
    ;;
  install) xcrun simctl install "$UDID" "${1:?Runner.app path required}" ;;
  launch) xcrun simctl launch "$UDID" "$APP_ID" ;;
  terminate) xcrun simctl terminate "$UDID" "$APP_ID" || true ;;
  axe)
    sub="${1:?axe subcommand required}"
    shift
    axe "$sub" "$@" --udid "$UDID"
    ;;
  screenshot)
    xcrun simctl io "$UDID" screenshot "${1:?file required}" >/dev/null 2>&1
    echo "{\"path\":\"$(cd "$(dirname "$1")" && pwd)/$(basename "$1")\"}"
    ;;
  files)
    # "On My iPhone" is the File Provider storage of the LocalStorage app group.
    data="$HOME/Library/Developer/CoreSimulator/Devices/$UDID/data"
    local_storage() {
      for g in "$data"/Containers/Shared/AppGroup/*; do
        id="$(plutil -extract MCMMetadataIdentifier raw "$g/.com.apple.mobile_container_manager.metadata.plist" 2>/dev/null || true)"
        if [ "$id" = "group.com.apple.FileProvider.LocalStorage" ]; then echo "$g/File Provider Storage"; return; fi
      done
    }
    storage="$(local_storage)"
    if [ -z "$storage" ]; then
      # Created the first time Files runs.
      xcrun simctl launch "$UDID" com.apple.DocumentsApp >/dev/null
      sleep 5
      storage="$(local_storage)"
    fi
    [ -n "$storage" ] || die "could not find the Files app's local storage"
    mkdir -p "$storage"
    cp "$@" "$storage/"
    log "copied $# file(s) to Files > On My iPhone"
    ;;
  open-url) xcrun simctl openurl "$UDID" "${1:?url required}" ;;
  simctl)
    sub="${1:?simctl subcommand required}"
    shift
    xcrun simctl "$sub" "$UDID" "$@"
    ;;
  down)
    xcrun simctl shutdown "$UDID" >/dev/null 2>&1 || true
    xcrun simctl delete "$UDID" >/dev/null 2>&1 || true
    rm -f "$STATE"
    log "deleted the simulator"
    ;;
  *)
    die "unknown command $CMD"
    ;;
esac
