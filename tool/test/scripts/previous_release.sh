#!/usr/bin/env bash
# Usage: tool/test/scripts/previous_release.sh <run>
#
# Downloads the assets of the previous published release (build.previous_release
# in the plan: "latest" or a tag) that the update tests start from into
# <run>/releases/<tag>/ and prints the tag. Uses the public GitHub API, set
# GITHUB_TOKEN in local.env to avoid rate limits.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

RUN="$(run_dir "${1:?usage: previous_release.sh <run>}")"
export E2E_PLAN="$RUN/test-plan.yaml"
REPO="juho05/sheetopia"
WANTED="$(plan get build.previous_release)"
WANTED="${WANTED:-latest}"

auth=()
[ -n "${GITHUB_TOKEN:-}" ] && auth=(-H "Authorization: Bearer $GITHUB_TOKEN")
api() { curl -fsSL --retry 3 ${auth[@]+"${auth[@]}"} -H "Accept: application/vnd.github+json" "https://api.github.com/repos/$REPO/$1"; }

if [ "$WANTED" = "latest" ]; then
  release="$(api releases/latest)"
else
  release="$(api "releases/tags/$WANTED")"
fi
TAG="$(jq -r .tag_name <<<"$release")"
DEST="$RUN/releases/$TAG"
mkdir -p "$DEST"

# Only what the update platforms and the simulator-less iOS need.
jq -r '.assets[] | select(.name | test("macOS-universal\\.dmg$|linux-x86-64\\.(AppImage|tar\\.gz)$|android-(arm64v8|x64)\\.apk$|SHA256SUMS\\.txt$")) | "\(.name)\t\(.browser_download_url)"' <<<"$release" |
  while IFS=$'\t' read -r name url; do
    if [ -s "$DEST/$name" ]; then continue; fi
    log "downloading $name"
    curl -fsSL --retry 3 -o "$DEST/$name.part" "$url"
    mv "$DEST/$name.part" "$DEST/$name"
  done

if [ -f "$DEST/"*SHA256SUMS.txt ]; then
  # Only check the files downloaded above.
  (cd "$DEST" && while read -r sum name; do if [ -f "$name" ]; then echo "$sum  $name"; fi; done <./*SHA256SUMS.txt |
    sha256 -c - >&2) ||
    die "checksum mismatch in $DEST"
fi
echo "$TAG"
