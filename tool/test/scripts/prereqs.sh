#!/usr/bin/env bash
# Usage: tool/test/scripts/prereqs.sh [--check] [--skip-images]
#
# Installs what the E2E harness needs on this host beyond a normal Flutter
# development setup (Flutter, Xcode / Android SDK, Docker on Linux are
# expected), and prepares the base images. Safe to re-run.
#
#   Mac (Apple Silicon): act, node, tart, sendmidi, axe, lilypond, the golden
#                        macOS test VM (~26 GB download, ~30 GB on disk)
#   Linux (x86_64):      act, jq, lilypond, the Android x86_64 emulator image,
#                        the desktop container image, the snd-virmidi module
#
#   --check        only report what is missing, exit 1 if anything is
#   --skip-images  don't download/build VM and container images
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

CHECK_ONLY=0
SKIP_IMAGES=0
for arg in "$@"; do
  case "$arg" in
    --check) CHECK_ONLY=1 ;;
    --skip-images) SKIP_IMAGES=1 ;;
    *) die "unknown argument $arg" ;;
  esac
done

missing=()
# need <name> <check command...>: logs ok or records it as missing (returns 1).
need() {
  local name="$1"; shift
  if "$@" >/dev/null 2>&1; then log "ok: $name"; return 0; fi
  missing+=("$name")
  return 1
}
installing() { [ $CHECK_ONLY = 0 ]; }

# Expected parts of a Flutter development setup, not installed here.
need flutter command -v flutter || die "install Flutter first"
need python3 command -v python3 || die "install python3 first (demo library generator)"

if [ "$E2E_HOST" = macos ]; then
  need xcode xcrun simctl help || die "install Xcode first"
  need brew command -v brew || die "install Homebrew first: https://brew.sh"
  mkdir -p "$E2E_BIN"
  # act + node run the release workflow's macOS job on this Mac.
  for formula in lilypond jq act node cameroncooke/axe/axe; do
    name="${formula##*/}"
    if ! need "$name" command -v "$name" && installing; then
      brew install "$formula"
    fi
  done
  # tart isn't installable through Homebrew anymore, use the release build.
  if ! need tart test -x "$E2E_HOME/tart.app/Contents/MacOS/tart" && installing; then
    log "installing tart $TART_VERSION"
    tmp="$(mktemp -d)"
    curl -fsSL --retry 3 -o "$tmp/tart.tar.gz" "$TART_URL"
    tar -xzf "$tmp/tart.tar.gz" -C "$tmp"
    rm -rf "$E2E_HOME/tart.app"
    mv "$tmp/tart.app" "$E2E_HOME/tart.app"
    rm -rf "$tmp"
  fi
  [ -x "$E2E_HOME/tart.app/Contents/MacOS/tart" ] && ln -sf "$E2E_HOME/tart.app/Contents/MacOS/tart" "$E2E_BIN/tart"
  # sendmidi creates virtual MIDI devices (macOS VM and iOS simulator).
  if ! need sendmidi test -x "$E2E_BIN/sendmidi" && installing; then
    log "installing sendmidi $SENDMIDI_VERSION"
    tmp="$(mktemp -d)"
    curl -fsSL --retry 3 -o "$tmp/sendmidi.zip" "$SENDMIDI_URL"
    unzip -q "$tmp/sendmidi.zip" -d "$tmp"
    # The release is an installer package, extract the binary without installing.
    pkgutil --expand-full "$(find "$tmp" -name '*.pkg' | head -1)" "$tmp/pkg"
    cp "$tmp/pkg/Payload/sendmidi" "$E2E_BIN/sendmidi"
    rm -rf "$tmp"
  fi
  if [ $SKIP_IMAGES = 0 ]; then
    if ! need macos-golden-vm bash -c "tart list --quiet --source local | grep -qx '$MACOS_GOLDEN_VM'" && installing; then
      "$E2E_SCRIPTS/macos_vm.sh" golden
    fi
  fi

elif [ "$E2E_HOST" = linux ]; then
  need docker docker info || die "Docker must be installed and usable without sudo"
  need kvm test -w /dev/kvm || die "the Android emulator needs /dev/kvm (enable virtualization, add yourself to the kvm group)"
  need android-sdk test -x "$ANDROID_SDK_ROOT/cmdline-tools/latest/bin/sdkmanager" ||
    die "Android SDK with cmdline-tools expected at $ANDROID_SDK_ROOT (set ANDROID_SDK_ROOT)"
  need java command -v java || die "install a JDK (17+) first"
  mkdir -p "$E2E_BIN"

  pkg_install() { # pkg_install <apt name> <dnf name> <pacman name>
    if command -v apt-get >/dev/null; then sudo apt-get install -y "$1"
    elif command -v dnf >/dev/null; then sudo dnf install -y "$2"
    elif command -v pacman >/dev/null; then sudo pacman -S --needed --noconfirm "$3"
    elif command -v zypper >/dev/null; then sudo zypper install -y "$2"
    else die "install $1 with your package manager"
    fi
  }
  if ! need jq command -v jq && installing; then pkg_install jq jq jq; fi
  if ! need lilypond command -v lilypond && installing; then pkg_install lilypond lilypond lilypond; fi

  if ! need act command -v act && installing; then
    log "installing act"
    curl -fsSL --retry 3 https://github.com/nektos/act/releases/latest/download/act_Linux_x86_64.tar.gz |
      tar -xz -C "$E2E_BIN" act
  fi

  if ! need android-emulator test -x "$ANDROID_SDK_ROOT/emulator/emulator" && installing; then
    yes | sdkmanager --licenses >/dev/null || true
    sdkmanager "emulator" "platform-tools"
  fi
  if ! need android-system-image test -d "$ANDROID_SDK_ROOT/system-images/android-$ANDROID_API/google_apis/x86_64" &&
    installing; then
    yes | sdkmanager --licenses >/dev/null || true
    sdkmanager "$ANDROID_SYSTEM_IMAGE"
  fi

  # Virtual MIDI devices for the Linux MIDI tests. The module only adds
  # virtual raw MIDI ports; it's loaded now and on boot.
  # Real MIDI interfaces also create midiC* devices, look for the module's cards.
  if ! need snd-virmidi grep -q VirMIDI /proc/asound/cards && installing; then
    sudo modprobe snd-virmidi
    echo snd-virmidi | sudo tee /etc/modules-load.d/sheetopia-e2e-virmidi.conf >/dev/null
  fi

  if [ $SKIP_IMAGES = 0 ]; then
    if ! need desktop-image docker image inspect "$LINUX_IMAGE" && installing; then
      "$E2E_SCRIPTS/linux_env.sh" image
    fi
    for image in "$ACT_IMAGE" "$ACT_IMAGE_22"; do
      if ! need "$image" docker image inspect "$image" && installing; then docker pull "$image"; fi
    done
  fi
else
  die "the harness runs on Apple Silicon Macs and x86_64 Linux"
fi

if installing; then
  for tool in plan drive vnc fake_github export_diff; do
    e2e_tool "$tool" --help >/dev/null || true
    need "harness-$tool" test -x "$(e2e_tool_path "$tool")"
  done
fi

[ "$E2E_HOST" = linux ] || [ -f "$E2E_DIR/local.env" ] || log "note: copy tool/test/local.env.example to tool/test/local.env and fill it in"

if [ $CHECK_ONLY = 1 ] && [ ${#missing[@]} -gt 0 ]; then
  log "missing: ${missing[*]}"
  exit 1
fi
log "prerequisites for $E2E_HOST ready"
