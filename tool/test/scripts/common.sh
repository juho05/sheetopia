#!/usr/bin/env bash
# Shared settings for the E2E harness scripts. Source it, don't run it.

E2E_SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
E2E_DIR="$(cd "$E2E_SCRIPTS/.." && pwd)"
REPO_DIR="$(cd "$E2E_DIR/../.." && pwd)"

# Downloaded tools, base images and caches shared by all runs, outside the repo.
E2E_HOME="${SHEETOPIA_E2E_HOME:-$HOME/.cache/sheetopia-e2e}"
E2E_BIN="$E2E_HOME/bin"
export PATH="$E2E_BIN:$PATH"

# The run splits by host: a Mac tests macOS and iOS, an x86_64 Linux machine
# tests Linux and Android (and runs the feature suite). See test-plan.yaml.
case "$(uname -s)/$(uname -m)" in
  Darwin/arm64) E2E_HOST=macos ;;
  Linux/x86_64) E2E_HOST=linux ;;
  *) E2E_HOST=unsupported ;;
esac

# --- macOS host -------------------------------------------------------------
TART_VERSION="2.41.0"
TART_URL="https://github.com/openai/tart/releases/download/$TART_VERSION/tart.tar.gz"
SENDMIDI_VERSION="1.4.4"
SENDMIDI_URL="https://github.com/gbevin/SendMIDI/releases/download/$SENDMIDI_VERSION/sendmidi-macOS-$SENDMIDI_VERSION.zip"
# Golden test VM; runs only ever use throwaway clones of it. The base image
# (guest agent, Homebrew, no Xcode, ~26 GB) is enough: builds run on the host.
MACOS_SOURCE_IMAGE="ghcr.io/cirruslabs/macos-tahoe-base:latest"
MACOS_GOLDEN_VM="sheetopia-e2e-macos-golden"
MACOS_VM_USER="admin"
IOS_DEVICE_TYPES=("iPhone 17" "iPad Pro 11-inch (M5)")

# --- Linux host -------------------------------------------------------------
# Desktop container for the Linux tests (built from tool/test/linux/).
LINUX_IMAGE="sheetopia-e2e-desktop:24.04"
LINUX_USER="sheetopia"
ACT_IMAGE="catthehacker/ubuntu:act-24.04"
ACT_IMAGE_22="catthehacker/ubuntu:act-22.04"

ANDROID_API="36"
ANDROID_SYSTEM_IMAGE="system-images;android-$ANDROID_API;google_apis;x86_64"
if [ "$E2E_HOST" = macos ]; then
  ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-${ANDROID_HOME:-$HOME/Library/Android/sdk}}"
else
  ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-${ANDROID_HOME:-$HOME/Android/Sdk}}"
fi
export ANDROID_SDK_ROOT ANDROID_HOME="$ANDROID_SDK_ROOT"
export PATH="$ANDROID_SDK_ROOT/platform-tools:$ANDROID_SDK_ROOT/emulator:$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$PATH"

APP_NAME="Sheetopia"
APP_ID="de.julianh.sheetopia"

# Machine specific settings (secrets, keystore paths). Never committed.
if [ -f "$E2E_DIR/local.env" ]; then
  # shellcheck disable=SC1091
  source "$E2E_DIR/local.env"
fi

# Portable helpers (GNU vs. BSD tools).
sed_i() { if sed --version >/dev/null 2>&1; then sed -i "$@"; else sed -i '' "$@"; fi; }
sha256() { if command -v sha256sum >/dev/null 2>&1; then sha256sum "$@"; else shasum -a 256 "$@"; fi; }
b64_file() { base64 <"$1" | tr -d '\n'; }
host_timezone() {
  if command -v timedatectl >/dev/null 2>&1; then
    timedatectl show -p Timezone --value 2>/dev/null && return
  fi
  readlink /etc/localtime | sed 's|.*/zoneinfo/||'
}

# Epoch seconds for `clock` offsets relative to the host's time: +15m, +2h,
# -1d, reset (= +0).
clock_target() {
  local offset="${1:?offset like +15m, +2h, +1d or reset}"
  [ "$offset" = reset ] && offset="+0"
  [[ "$offset" =~ ^([+-])([0-9]+)([smhd]?)$ ]] || die "offset like +15m, +2h, +1d or reset"
  local n="${BASH_REMATCH[2]}" unit="${BASH_REMATCH[3]:-s}"
  case "$unit" in m) n=$((n * 60)) ;; h) n=$((n * 3600)) ;; d) n=$((n * 86400)) ;; esac
  [ "${BASH_REMATCH[1]}" = - ] && n=$((-n))
  echo $(($(date +%s) + n))
}

log() { printf '[%s] %s\n' "$(date +%H:%M:%S)" "$*" >&2; }
die() { log "error: $*"; exit 1; }

# Resolves a run directory from its id (or path) and fails if it doesn't exist.
run_dir() {
  local id="${1:?run id required}"
  if [ -d "$id" ]; then (cd "$id" && pwd); return; fi
  local dir="$E2E_DIR/runs/$id"
  [ -d "$dir" ] || die "no run directory $dir"
  echo "$dir"
}

e2e_tool_path() { echo "$E2E_DIR/harness/.dart_tool/e2e/$(uname -s)-$(uname -m)/$1"; }

# Runs one of the Dart tools in harness/bin, compiled to a native executable
# (recompiled when any harness source changed).
e2e_tool() {
  local name="${1:?tool name required}"; shift
  local exe="$(e2e_tool_path "$name")"
  local src="$E2E_DIR/harness/bin/$name.dart"
  [ -f "$src" ] || die "no harness tool $name"
  if [ ! -x "$exe" ] || [ -n "$(find "$E2E_DIR/harness/bin" "$E2E_DIR/harness/pubspec.yaml" -newer "$exe" 2>/dev/null | head -1)" ]; then
    # pub get every time: a .dart_tool copied from the other host points into its pub cache.
    (cd "$E2E_DIR/harness" && flutter pub get >&2 &&
      mkdir -p "$(dirname "$exe")" && dart compile exe "bin/$name.dart" -o "$exe" >&2) || die "failed to compile $name"
  fi
  "$exe" "$@"
}

# The plan of the current run (runs keep a copy so edits mid-run are harmless).
plan() { e2e_tool plan --plan "${E2E_PLAN:-$E2E_DIR/test-plan.yaml}" "$@"; }
