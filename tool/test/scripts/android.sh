#!/usr/bin/env bash
# Usage: tool/test/scripts/android.sh <command> <run> [args]
#
# A throwaway Android emulator (AVD lives in the run directory, wiped on
# boot), separate from any AVD or device of the host.
#
#   up <run>                       create and boot the emulator
#   provision <run> [<release>]    up, install the build under test (or the
#                                  release dir, e.g. v0.7.0), put
#                                  demo-library.zip into Download/
#   snapshot <run> save|restore <name>
#                                  app data to/from <run>/snapshots/
#                                  (stops the app, restore leaves it stopped
#                                  and empties Download/ but demo-library.zip)
#   adb <run> <adb args...>        adb against this emulator only
#   screenshot <run> <file.png>
#   tap <run> X Y | swipe <run> X1 Y1 X2 Y2 [ms] | text <run> <text>
#   key <run> <keycode>            e.g. KEYCODE_BACK, KEYCODE_HOME
#   clock <run> +15m|+2h|-1d|reset set the clock relative to the host's time
#   stylus <run> tap X Y | stylus <run> swipe X1 Y1 X2 Y2 [ms]
#   ui <run>                       accessibility tree (uiautomator dump)
#   push-files <run> <file>...     copy files to /sdcard/Download and index
#                                  them, prints their content:// URIs
#   fake-github <run> <url|off>    point the app's update check at a server
#                                  (the host is 10.0.2.2 from the emulator)
#   down <run>                     kill the emulator and delete the AVD
#
# Coordinates are screen pixels as in the screenshots. State:
# <run>/env/android.env.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

CMD="${1:?usage: android.sh <command> <run> [args]}"
RUN="$(run_dir "${2:?run required}")"
shift 2
STATE="$RUN/env/android.env"
export ANDROID_AVD_HOME="$RUN/env/avd"
AVD="sheetopia-e2e"

if [ "$CMD" != "up" ] && [ "$CMD" != "provision" ]; then
  [ -f "$STATE" ] || die "the emulator of this run is not up"
  # shellcheck disable=SC1090
  source "$STATE"
fi
dev() { adb -s "$SERIAL" "$@"; }

case "$CMD" in
  up)
    mkdir -p "$ANDROID_AVD_HOME" "$RUN/logs"
    echo no | avdmanager -s create avd -n "$AVD" -k "$ANDROID_SYSTEM_IMAGE" -d pixel_7 --force >/dev/null
    # More RAM and storage than the default. avdmanager writes its own
    # defaults for these, which would win.
    sed_i -E '/^(hw\.ramSize|disk\.dataPartition\.size)=/d' "$ANDROID_AVD_HOME/$AVD.avd/config.ini"
    {
      echo "hw.ramSize=3072"
      echo "disk.dataPartition.size=6G"
    } >>"$ANDROID_AVD_HOME/$AVD.avd/config.ini"
    port=5580
    while adb devices | grep -q "emulator-$port"; do port=$((port + 2)); done
    SERIAL="emulator-$port"
    nohup emulator -avd "$AVD" -port "$port" -no-window -no-audio -no-boot-anim -no-snapshot \
      -wipe-data -gpu swiftshader_indirect >"$RUN/logs/emulator.log" 2>&1 &
    echo "SERIAL=$SERIAL" >"$STATE"
    echo "PID=$!" >>"$STATE"
    log "booting $SERIAL"
    adb -s "$SERIAL" wait-for-device
    for _ in $(seq 1 120); do
      [ "$(adb -s "$SERIAL" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = "1" ] && break
      sleep 5
    done
    [ "$(adb -s "$SERIAL" shell getprop sys.boot_completed | tr -d '\r')" = "1" ] || die "emulator did not boot"
    adb -s "$SERIAL" root >/dev/null 2>&1 || true
    adb -s "$SERIAL" wait-for-device
    # Same time zone as the host, no animations slowing the agent down, stay awake.
    tz="$(host_timezone)"
    adb -s "$SERIAL" shell "setprop persist.sys.timezone '$tz'; settings put global window_animation_scale 0.5; settings put global transition_animation_scale 0.5; svc power stayon true; input keyevent KEYCODE_WAKEUP; wm dismiss-keyguard" >/dev/null 2>&1 || true
    # Chrome opens links without its first-run screens.
    adb -s "$SERIAL" shell "echo 'chrome --disable-fre --no-default-browser-check --no-first-run' >/data/local/tmp/chrome-command-line;
      chmod 644 /data/local/tmp/chrome-command-line; am set-debug-app --persistent com.android.chrome;
      pm grant com.android.chrome android.permission.POST_NOTIFICATIONS" >/dev/null 2>&1 || true
    cat "$STATE"
    ;;
  provision)
    "$0" up "$RUN" >/dev/null
    # shellcheck disable=SC1090
    source "$STATE"
    release="${1:-v$(jq -r .versions.current "$RUN/run.json")}"
    apk="$(ls "$RUN/releases/$release/"*x64*.apk | head -1)"
    dev install -r "$apk" >/dev/null
    "$0" push-files "$RUN" "$RUN/demo-library.zip" >/dev/null
    log "installed $(basename "$apk")"
    ;;
  snapshot)
    action="${1:?save or restore}"
    file="$RUN/snapshots/android-${2:?snapshot name required}.tar"
    data="/data/data/$APP_ID"
    # cache dirs have their own group and are left alone.
    entries="ls -A | grep -v -x -e cache -e code_cache"
    dev shell am force-stop "$APP_ID"
    case "$action" in
      save)
        mkdir -p "$RUN/snapshots"
        dev exec-out "cd $data && tar -cf - \$($entries)" >"$file.tmp"
        mv "$file.tmp" "$file"
        ;;
      restore)
        [ -f "$file" ] || die "no snapshot $file"
        dev push "$file" /data/local/tmp/e2e-snapshot.tar >/dev/null
        # restorecon would drop the app's SELinux categories, copy the dir's context instead.
        dev shell "cd $data && owner=\$(stat -c %u .) && context=\$(stat -c %C .) && rm -rf \$($entries) && tar -xf /data/local/tmp/e2e-snapshot.tar &&
          chown -R \$owner:\$owner \$($entries) && chcon -R \$context \$($entries) && rm /data/local/tmp/e2e-snapshot.tar"
        # Files earlier tests pushed or exported, from disk and the media store.
        dev shell "find /sdcard/Download -mindepth 1 ! -name demo-library.zip -exec rm -rf {} +;
          content delete --uri content://media/external/file --where \"_data LIKE '/storage/emulated/0/Download/%' AND _display_name != 'demo-library.zip'\""
        dev shell input keyevent KEYCODE_HOME
        "$0" clock "$RUN" reset 2>/dev/null
        ;;
      *) die "snapshot save|restore <name>" ;;
    esac
    log "snapshot $action ${2}"
    ;;
  clock)
    target="$(clock_target "${1:-}")"
    if [ "$1" = reset ]; then auto=1; else auto=0; fi
    dev shell "settings put global auto_time $auto; date $(date -d "@$target" +%m%d%H%M%Y.%S)" >/dev/null
    log "emulator clock: $(dev shell date)"
    ;;
  adb)
    dev "$@"
    ;;
  screenshot)
    dev exec-out screencap -p >"${1:?file required}"
    echo "{\"path\":\"$(cd "$(dirname "$1")" && pwd)/$(basename "$1")\"}"
    ;;
  tap) dev shell input tap "${1:?x}" "${2:?y}" ;;
  swipe) dev shell input swipe "${1:?}" "${2:?}" "${3:?}" "${4:?}" "${5:-300}" ;;
  text)
    # input text needs spaces escaped.
    dev shell input text "$(printf '%s' "${1:?text required}" | sed 's/ /%s/g; s/[&|<>;()$`\\"'"'"']/\\&/g')"
    ;;
  key) dev shell input keyevent "${1:?keycode required}" ;;
  stylus)
    sub="${1:?tap or swipe}"
    shift
    case "$sub" in
      tap) dev shell input stylus tap "${1:?}" "${2:?}" ;;
      swipe) dev shell input stylus swipe "${1:?}" "${2:?}" "${3:?}" "${4:?}" "${5:-400}" ;;
      *) die "stylus tap|swipe" ;;
    esac
    ;;
  ui)
    dev shell uiautomator dump /sdcard/e2e-ui.xml >/dev/null
    dev exec-out cat /sdcard/e2e-ui.xml
    echo
    ;;
  push-files)
    for f in "$@"; do
      name="$(basename "$f")"
      dev push "$f" "/sdcard/Download/$name" >/dev/null
      dev shell am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d "file:///sdcard/Download/$name" >/dev/null
    done
    sleep 2
    for f in "$@"; do
      name="$(basename "$f")"
      id="$(dev shell content query --uri content://media/external/file --projection _id --where "\"_display_name='$name'\"" |
        sed -n 's/.*_id=\([0-9]*\).*/\1/p' | tail -1)"
      if [ -n "$id" ]; then
        echo "content://media/external/file/$id"
      else
        log "warning: $name not indexed by the media store"
      fi
    done
    ;;
  fake-github)
    url="${1:?url or off}"
    [ "$url" = "off" ] && url=""
    dev shell setprop debug.sheetopia.github_api_url "'$url'"
    dev shell setprop debug.sheetopia.github_web_url "'$url'"
    log "set debug.sheetopia.github_*_url to '${url}', restart the app to apply"
    ;;
  down)
    adb -s "$SERIAL" emu kill >/dev/null 2>&1 || true
    sleep 3
    kill "$PID" 2>/dev/null || true
    rm -rf "$ANDROID_AVD_HOME" "$STATE"
    log "deleted the emulator"
    ;;
  *)
    die "unknown command $CMD"
    ;;
esac
