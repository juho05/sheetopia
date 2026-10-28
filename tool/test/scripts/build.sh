#!/usr/bin/env bash
# Usage: tool/test/scripts/build.sh <run> [--stage current|next]... [--only <part>]...
#
# Builds the staged trees of a run for the platforms of this host, using the
# release workflow (.github/workflows/release.yml) through act where the
# release has a job for it:
#
#   Mac host
#     macos    the signed .dmg job, act self-hosted on this Mac, signing with
#              the Developer ID in the login keychain (keychains stay untouched)
#     ios      a simulator build (the release .ipa can't run in a simulator)
#   Linux host
#     host     the ubuntu jobs natively in Docker: tests, Linux tar.gz and
#              AppImage, Android APKs
#     e2e      the Linux profile build with the driver extension for the
#              feature suite (tool/test/app/main_e2e.dart), built in an Ubuntu
#              24.04 container so it runs in the test desktop
#
# Results land in <run>/releases/v<version>/ under the release asset names
# (the release job's renames) and <run>/builds/<stage>/. Logs:
# <run>/logs/build-*.log. Secrets come from local.env and only live in
# <run>/env/act-secrets.env (deleted afterwards) and the build containers.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

RUN="$(run_dir "${1:?usage: build.sh <run> [--stage name]... [--only part]...}")"
shift
export E2E_PLAN="$RUN/test-plan.yaml"
stages=()
parts=()
while [ $# -gt 0 ]; do
  case "$1" in
    --stage) stages+=("${2:?}"); shift 2 ;;
    --only) parts+=("${2:?}"); shift 2 ;;
    *) die "unknown argument $1" ;;
  esac
done
if [ ${#stages[@]} -eq 0 ]; then
  for s in current next; do [ -d "$RUN/stage/$s" ] && stages+=("$s"); done
fi
platform_on() {
  plan enabled "platforms.$1.enabled" && [ "$(plan get "platforms.$1.host")" = "$E2E_HOST" ]
}
if [ ${#parts[@]} -eq 0 ]; then
  case "$E2E_HOST" in
    macos)
      platform_on macos && parts+=(macos)
      platform_on ios && parts+=(ios)
      ;;
    linux)
      { platform_on linux || platform_on android; } && parts+=(host)
      platform_on linux && plan enabled phases.feature_suite.enabled && parts+=(e2e)
      ;;
    *) die "unsupported host $(uname -sm)" ;;
  esac
fi
want() { [[ " ${parts[*]-} " == *" $1 "* ]]; }

mkdir -p "$RUN/logs" "$RUN/env" "$RUN/builds"
SECRETS="$RUN/env/act-secrets.env"
summary="$RUN/builds/summary.tsv"
touch "$summary"
# Replaces the step's row, so rebuilding one part keeps the others' results.
note() {
  awk -F'\t' -v stage="$1" -v step="$2" '!($1 == stage && $2 == step)' "$summary" >"$summary.tmp"
  mv "$summary.tmp" "$summary"
  printf '%s\t%s\t%s\n' "$1" "$2" "$3" >>"$summary"
  log "$1 $2: $3"
}
version_of() { cat "$RUN/stage/$1/.e2e_version"; }
release_dir() { local d="$RUN/releases/v$(version_of "$1")"; mkdir -p "$d"; echo "$d"; }

umask 077
: >"$SECRETS"
key_properties="${ANDROID_KEY_PROPERTIES:-$REPO_DIR/android/key.properties}"
key_properties="${key_properties/#\~/$HOME}"
keystore="${ANDROID_KEYSTORE:-}"
if [ -z "$keystore" ] && [ -f "$key_properties" ]; then
  keystore="$(sed -n 's/^storeFile=//p' "$key_properties" | tr -d '\r')"
  # Gradle resolves it relative to android/app.
  case "$keystore" in /* | \~* | "") ;; *) keystore="$REPO_DIR/android/app/$keystore" ;; esac
fi
keystore="${keystore/#\~/$HOME}"
if [ -f "$key_properties" ] && [ -f "$keystore" ]; then
  echo "ANDROID_KEY_STORE=$(b64_file "$keystore")" >>"$SECRETS"
  # The workflow puts the keystore at android/app/secrets/sheetopia.jks.
  echo "ANDROID_KEY_PROPERTIES=$(sed 's|^storeFile=.*|storeFile=secrets/sheetopia.jks|' "$key_properties" | base64 | tr -d '\n')" >>"$SECRETS"
fi
if [ -n "${MACOS_CERTIFICATE_NAME:-}" ]; then
  # Under act the macOS job signs with this identity from the login keychain.
  echo "PROD_MACOS_CERTIFICATE_NAME=$MACOS_CERTIFICATE_NAME" >>"$SECRETS"
fi
umask 022
cleanup() { rm -f "$SECRETS"; }
trap cleanup EXIT

# Finds an uploaded act artifact by name and unpacks it into a directory.
extract_artifact() { # extract_artifact <stage> <artifact name> <dest dir>
  local base="$RUN/builds/$1/act-artifacts" dest="$3" found
  mkdir -p "$dest"
  found="$(find "$base" -path "*/$2/*" -type f 2>/dev/null | head -1)"
  [ -z "$found" ] && found="$(find "$base" -type f -name "$2*.zip" 2>/dev/null | head -1)"
  [ -n "$found" ] || return 1
  case "$found" in
    *.zip) unzip -o -q "$found" -d "$dest" ;;
    *) cp "$(dirname "$found")"/* "$dest/" ;;
  esac
}

# --- Linux host: ubuntu jobs --------------------------------------------------

act_host() { # act_host <stage> <job>
  local stage="$1" job="$2" artifacts="$RUN/builds/$1/act-artifacts"
  mkdir -p "$artifacts"
  log "act: $job ($stage)"
  (cd "$RUN/stage/$stage" && act workflow_dispatch -W .github/workflows/release.yml -j "$job" \
    --input upload_app_store=false --secret-file "$SECRETS" --rm --container-daemon-socket - \
    -P "ubuntu-latest=$ACT_IMAGE" -P "ubuntu-24.04=$ACT_IMAGE" -P "ubuntu-22.04=$ACT_IMAGE_22" \
    --artifact-server-path "$artifacts") >"$RUN/logs/build-$stage-$job.log" 2>&1
}
run_job() { # run_job <stage> <job>
  if act_host "$1" "$2"; then note "$1" "$2" ok; else note "$1" "$2" "FAILED (logs/build-$1-$2.log)"; return 1; fi
}

if want host; then
  docker info >/dev/null 2>&1 || die "Docker isn't usable by $(whoami)"
  for stage in "${stages[@]}"; do
    v="$(version_of "$stage")"
    rel="$(release_dir "$stage")"
    if [ "$stage" = current ]; then run_job current test || true; fi
    if platform_on linux; then
      if run_job "$stage" build_linux_x86_64_TGZ && extract_artifact "$stage" tar-gz-x86-64-result "$RUN/builds/$stage/linux"; then
        cp "$RUN/builds/$stage/linux/"*.tar.gz "$rel/Sheetopia-$v-linux-x86-64.tar.gz"
      fi
      if run_job "$stage" build_linux_x86_64_AppImage && extract_artifact "$stage" appimage-x86-64-result "$RUN/builds/$stage/linux"; then
        cp "$RUN/builds/$stage/linux/Sheetopia-$v-linux-x86-64.AppImage"* "$rel/"
      fi
    fi
    if platform_on android; then
      if ! grep -q '^ANDROID_KEY_STORE=' "$SECRETS"; then
        note "$stage" build_android "SKIPPED (no android/key.properties with an existing storeFile)"
      elif run_job "$stage" build_android && extract_artifact "$stage" android-apk-result "$RUN/builds/$stage/android"; then
        a="$RUN/builds/$stage/android"
        cp "$a/app-arm64-v8a-release.apk" "$rel/Sheetopia-$v-android-arm64v8.apk"
        cp "$a/app-armeabi-v7a-release.apk" "$rel/Sheetopia-$v-android-arm32v7.apk"
        cp "$a/app-x86_64-release.apk" "$rel/Sheetopia-$v-android-x64.apk"
        if [ -f "$a/app-release.apk" ]; then cp "$a/app-release.apk" "$rel/Sheetopia-$v-android.apk"; fi
      fi
    fi
  done
fi

# --- Linux host: E2E profile build --------------------------------------------

if want e2e; then
  flutter_version="$(sed -n 's/^ *FLUTTER_VERSION: *"\(.*\)"/\1/p' "$RUN/stage/current/.github/workflows/release.yml")"
  sdk="$E2E_HOME/flutter-$flutter_version"
  if [ ! -x "$sdk/bin/flutter" ]; then
    log "downloading Flutter $flutter_version for the E2E build"
    mkdir -p "$E2E_HOME"
    rm -rf "$E2E_HOME/flutter"
    curl -fL --retry 3 "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_$flutter_version-stable.tar.xz" |
      tar -xJ -C "$E2E_HOME"
    mv "$E2E_HOME/flutter" "$sdk"
  fi
  mkdir -p "$E2E_HOME/pub-cache"
  log "flutter build linux --profile (E2E driver build, in Ubuntu 24.04)"
  # Packages are installed as root, the build runs as the host user so the
  # SDK, pub cache and stage stay owned by them.
  if docker run --rm -e HOME=/tmp/home -e PUB_CACHE=/cache/pub -e HOST_UID="$(id -u)" -e HOST_GID="$(id -g)" \
      -v "$RUN/stage/current:/src" -v "$sdk:/flutter" -v "$E2E_HOME/pub-cache:/cache/pub" -w /src \
      "$ACT_IMAGE" bash -c '
        set -e
        apt-get update -qq && apt-get install -y -qq clang cmake libgtk-3-dev ninja-build >/dev/null
        setpriv --reuid="$HOST_UID" --regid="$HOST_GID" --clear-groups bash -e <<"EOF"
mkdir -p "$HOME"
git config --global --add safe.directory "*"
/flutter/bin/flutter --suppress-analytics config --no-analytics >/dev/null
/flutter/bin/flutter pub get >/dev/null
/flutter/bin/flutter build linux --profile -t tool/test/app/main_e2e.dart
EOF
      ' >"$RUN/logs/build-current-linux-e2e.log" 2>&1; then
    rm -rf "$RUN/builds/current/linux-e2e"
    mkdir -p "$RUN/builds/current"
    cp -R "$RUN/stage/current/build/linux/x64/profile/bundle" "$RUN/builds/current/linux-e2e"
    note current linux-e2e ok
  else
    note current linux-e2e "FAILED (logs/build-current-linux-e2e.log)"
  fi
fi

# --- Mac host: the .dmg job ------------------------------------------------------

if want macos; then
  if [ -z "${MACOS_CERTIFICATE_NAME:-}" ] ||
    ! security find-identity -v -p codesigning | grep -qF "\"$MACOS_CERTIFICATE_NAME\""; then
    note all build_macos_dmg "SKIPPED (MACOS_CERTIFICATE_NAME in local.env is not a codesigning identity in the keychain)"
  else
    for stage in "${stages[@]}"; do
      v="$(version_of "$stage")"
      rel="$(release_dir "$stage")"
      artifacts="$RUN/builds/$stage/act-artifacts"
      mkdir -p "$artifacts"
      log "act: build_macos_dmg ($stage, on this Mac)"
      # Self-hosted: the job runs directly here. Under act it signs with the
      # login keychain's identity, skips notarization and installs nothing
      # globally (see the ACT guards in release.yml).
      if (cd "$RUN/stage/$stage" && act workflow_dispatch -W .github/workflows/release.yml -j build_macos_dmg \
          --input upload_app_store=false --secret-file "$SECRETS" \
          -P macos-latest=-self-hosted -P ubuntu-latest=-self-hosted \
          --artifact-server-path "$artifacts") >"$RUN/logs/build-$stage-build_macos_dmg.log" 2>&1; then
        note "$stage" build_macos_dmg ok
      else
        note "$stage" build_macos_dmg "FAILED (logs/build-$stage-build_macos_dmg.log)"
      fi
      if extract_artifact "$stage" macos-dmg-result "$RUN/builds/$stage/macos"; then
        cp "$RUN/builds/$stage/macos/Sheetopia.dmg" "$rel/Sheetopia-$v-macOS-universal.dmg"
      fi
    done
  fi
fi

# --- Mac host: iOS simulator build --------------------------------------------

if want ios; then
  log "flutter build ios --simulator (current)"
  if (cd "$RUN/stage/current" && flutter build ios --simulator --debug) >"$RUN/logs/build-current-ios-sim.log" 2>&1; then
    mkdir -p "$RUN/builds/current/ios"
    rm -rf "$RUN/builds/current/ios/Runner.app"
    cp -R "$RUN/stage/current/build/ios/iphonesimulator/Runner.app" "$RUN/builds/current/ios/"
    note current ios-simulator ok
  else
    note current ios-simulator "FAILED (logs/build-current-ios-sim.log)"
  fi
fi

for stage in "${stages[@]}"; do
  rel="$RUN/releases/v$(version_of "$stage")"
  if [ -d "$rel" ] && [ -n "$(ls "$rel")" ]; then
    # Asset names never contain spaces.
    # shellcheck disable=SC2046
    (cd "$rel" && sha256 $(ls | grep -v SHA256SUMS) >"Sheetopia-$(version_of "$stage")-SHA256SUMS.txt")
  fi
done

cat "$summary"
! grep -q FAILED "$summary"
