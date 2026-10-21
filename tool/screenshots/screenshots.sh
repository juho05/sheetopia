#!/usr/bin/env bash
# Usage: tool/screenshots/screenshots.sh [options], see README.md or --help.
set -euo pipefail
cli="$(cd "$(dirname "${BASH_SOURCE[0]}")/cli" && pwd)"
(cd "$cli" && flutter pub get >/dev/null)
exec dart run "$cli/bin/screenshots.dart" "$@"
