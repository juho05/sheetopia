#!/usr/bin/env bash
# Usage: tool/test/scripts/stage.sh <run> <name> [--bump major|minor|patch]
#
# Copies the working tree (tracked and untracked, not ignored files, so
# uncommitted changes are included) to <run>/stage/<name> as a fresh one-commit
# git repo for act to build. The repo itself is never touched.
#
# - build.local_packages from the plan are vendored into .e2e_packages/ and
#   used via dependency_overrides (git refs can't see unpushed changes).
# - --bump raises the version (and build number), for the imaginary next
#   release.
# - pubspec.lock is refreshed so `pub get --enforce-lockfile` passes.
#
# Prints the staged directory and its version.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

RUN="$(run_dir "${1:?usage: stage.sh <run> <name> [--bump part]}")"
NAME="${2:?usage: stage.sh <run> <name> [--bump part]}"
BUMP=""
if [ "${3:-}" = "--bump" ]; then BUMP="${4:?--bump needs major, minor or patch}"; fi
export E2E_PLAN="$RUN/test-plan.yaml"

DEST="$RUN/stage/$NAME"
rm -rf "$DEST"
mkdir -p "$DEST"

copy_tree() { # copy_tree <git dir> <dest>
  # Tracked files deleted in the working tree are skipped.
  (
    cd "$1"
    git ls-files -co --exclude-standard -z | while IFS= read -r -d '' f; do
      [ -e "$f" ] || [ -L "$f" ] && printf '%s\0' "$f"
    done | tar --null -T - -cf -
  ) | tar -xf - -C "$2"
}

log "staging working tree into $DEST"
copy_tree "$REPO_DIR" "$DEST"
rm -rf "$DEST/tool/test/runs"

overrides=""
while IFS=$'\t' read -r pkg path; do
  [ -n "$pkg" ] || continue
  path="${path/#\~/$HOME}"
  [ -d "$path" ] || die "local package $pkg not found at $path"
  log "vendoring local $pkg from $path"
  mkdir -p "$DEST/.e2e_packages/$pkg"
  copy_tree "$path" "$DEST/.e2e_packages/$pkg"
  overrides+="  $pkg:"$'\n'"    path: ./.e2e_packages/$pkg"$'\n'
  (cd "$path" && echo "$pkg $(git rev-parse --short HEAD)$(git diff --quiet HEAD || echo ' +uncommitted changes')") \
    >>"$DEST/.e2e_packages/VERSIONS"
done < <(plan get build.local_packages | jq -r 'to_entries[] | "\(.key)\t\(.value)"' 2>/dev/null || true)

if [ -n "$overrides" ]; then
  # Append to the existing dependency_overrides section.
  ADD="$overrides" awk '
    { print }
    /^dependency_overrides:/ { printf "%s", ENVIRON["ADD"]; done = 1 }
    END { if (!done) printf "\ndependency_overrides:\n%s", ENVIRON["ADD"] }
  ' "$DEST/pubspec.yaml" >"$DEST/pubspec.yaml.tmp"
  mv "$DEST/pubspec.yaml.tmp" "$DEST/pubspec.yaml"
fi

VERSION_LINE="$(sed -n 's/^version: //p' "$DEST/pubspec.yaml")"
VERSION="${VERSION_LINE%%+*}"
BUILD=0
[[ "$VERSION_LINE" == *+* ]] && BUILD="${VERSION_LINE#*+}"
if [ -n "$BUMP" ]; then
  IFS=. read -r major minor patch <<<"$VERSION"
  case "$BUMP" in
    major) VERSION="$((major + 1)).0.0" ;;
    minor) VERSION="$major.$((minor + 1)).0" ;;
    patch) VERSION="$major.$minor.$((patch + 1))" ;;
    *) die "unknown bump $BUMP" ;;
  esac
  BUILD="$((BUILD + 1))"
  sed_i "s/^version: .*/version: $VERSION+$BUILD/" "$DEST/pubspec.yaml"
  log "bumped version to $VERSION+$BUILD"
fi

log "refreshing pubspec.lock"
(cd "$DEST" && flutter pub get >"$RUN/logs/stage-$NAME-pub.log" 2>&1) ||
  die "flutter pub get failed in the staged tree, see $RUN/logs/stage-$NAME-pub.log"

echo "$VERSION" >"$DEST/.e2e_version"
(
  cd "$DEST"
  git init -q -b e2e
  git add -A
  git -c user.name=e2e -c user.email=e2e@localhost -c commit.gpgsign=false commit -qm "E2E stage $NAME ($VERSION+$BUILD)"
  # act derives github.repository(_owner) from it, nothing is ever pushed.
  git remote add origin https://github.com/juho05/sheetopia.git
)

printf '%s\t%s\n' "$DEST" "$VERSION"
