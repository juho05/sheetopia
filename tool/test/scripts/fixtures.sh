#!/usr/bin/env bash
# Usage: tool/test/scripts/fixtures.sh <run>
#
# Creates <run>/fixtures/ with test files from the run's demo library:
#   valid/       PDFs named after their titles (single and multi-page)
#   many/        40 distinct PDFs for bulk imports
#   invalid/     notes.txt, image.png, fake.pdf, corrupt.pdf, archive.zip,
#                no-marker.zip
#   demo-library.zip
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

RUN="$(run_dir "${1:?usage: fixtures.sh <run>}")"
OUT="$RUN/fixtures"
rm -rf "$OUT"
mkdir -p "$OUT/valid" "$OUT/many" "$OUT/invalid"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

unzip -q "$RUN/demo-library.zip" -d "$tmp/demo"
cp "$RUN/demo-library.zip" "$OUT/demo-library.zip"

# Library scores (not exercise-only ones), named after their title.
jq -r '.[] | select(.type == "score") | "\(.id)\t\(.title)"' "$tmp/demo/scores.json" |
  while IFS=$'\t' read -r id title; do
    name="$(printf '%s' "$title" | LC_ALL=C tr -c 'A-Za-z0-9-' '_' | tr -s '_' | sed 's/_$//')"
    cp "$tmp/demo/scores/$id/score.pdf" "$OUT/valid/$name.pdf"
  done

i=0
while [ $i -lt 40 ]; do
  for f in "$OUT"/valid/*.pdf; do
    [ $i -ge 40 ] && break
    i=$((i + 1))
    # Append a comment so every copy has its own content hash.
    { cat "$f"; printf '\n%% sheetopia e2e copy %d\n' "$i"; } >"$OUT/many/$(printf 'bulk-%02d' "$i")-$(basename "$f")"
  done
done

printf 'Not a score.\n' >"$OUT/invalid/notes.txt"
# 1x1 PNG
base64 -d >"$OUT/invalid/image.png" <<<'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg=='
printf 'This is plain text pretending to be a PDF.\n' >"$OUT/invalid/fake.pdf"
first="$(ls "$OUT"/valid/*.pdf | head -1)"
head -c 2000 "$first" >"$OUT/invalid/corrupt.pdf"
(cd "$tmp" && mkdir -p rnd && printf 'hello\n' >rnd/readme.txt && zip -q -r "$OUT/invalid/archive.zip" rnd)
(cd "$tmp/demo" && zip -q -r "$OUT/invalid/no-marker.zip" . -x .sheetopia)

log "fixtures in $OUT: $(ls "$OUT/valid" | wc -l | tr -d ' ') valid, 40 bulk, $(ls "$OUT/invalid" | wc -l | tr -d ' ') invalid"
