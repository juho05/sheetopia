#!/usr/bin/env bash
# Usage: tool/test/scripts/tool.sh <drive|fake_github|export_diff|plan|e2e> [args...]
# Runs a harness Dart tool (see tool/test/harness/bin), compiling it if needed.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
e2e_tool "$@"
