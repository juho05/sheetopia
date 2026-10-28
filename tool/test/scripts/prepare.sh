#!/usr/bin/env bash
# Usage: tool/test/scripts/prepare.sh <run id> [--set path=value]...
#
# Creates tool/test/runs/<run id>/ for a test run:
#   test-plan.yaml     snapshot of the plan with the --set overrides applied
#   run.json           commit, version, start time, enabled phases/platforms
#   demo-library.zip   freshly generated demo library (--now = run start)
#   fixtures/          test files (scripts/fixtures.sh)
#   stage/current      the build under test (scripts/stage.sh)
#   stage/next         the same with a bumped version (imaginary next release)
#                      and the test upgrade messages
#   upgrade-messages-next.json  those messages
#   stage/plain        bumped once more, without upgrade messages, if an
#                      upgrade_messages test of this host needs it
#   contents/<tag>/    the repository files the fake GitHub serves per tag
#   releases/<tag>/    previous release assets, if old_to_new_update is on
# and prints run.json. Fails fast when prerequisites are missing.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

ID="${1:?usage: prepare.sh <run id> [--set path=value]...}"
shift
sets=()
while [ $# -gt 0 ]; do
  case "$1" in
    --set) sets+=(--set "${2:?--set needs path=value}"); shift 2 ;;
    *) die "unknown argument $1" ;;
  esac
done

"$E2E_SCRIPTS/prereqs.sh" --check >&2 || die "prerequisites missing, run tool/test/scripts/prereqs.sh"

RUN="$E2E_DIR/runs/$ID"
[ -e "$RUN" ] && die "run $ID already exists"
mkdir -p "$RUN/logs" "$RUN/results" "$RUN/screenshots"
RUN="$(cd "$RUN" && pwd)"
STARTED="$(date +%Y-%m-%dT%H:%M:%S)"

# Snapshot the plan with overrides applied (re-serialised as JSON, which is
# valid YAML).
E2E_PLAN="$E2E_DIR/test-plan.yaml" plan ${sets[@]+"${sets[@]}"} json >"$RUN/test-plan.yaml"
export E2E_PLAN="$RUN/test-plan.yaml"

log "generating the demo library"
demo_args=(-o "$RUN/demo-library.zip" --now "${STARTED%:*}")
plan enabled demo_library.rebuild_scores && demo_args+=(--clean)
python3 "$REPO_DIR/tool/demo_library/build.py" "${demo_args[@]}" >"$RUN/logs/demo-library.log" 2>&1 ||
  die "demo library build failed, see $RUN/logs/demo-library.log"

"$E2E_SCRIPTS/fixtures.sh" "$RUN" >&2
"$E2E_SCRIPTS/stage.sh" "$RUN" current >&2
CURRENT_VERSION="$(cat "$RUN/stage/current/.e2e_version")"
NEXT_VERSION=""
if plan enabled phases.new_to_next_update.enabled || plan enabled phases.upgrade_messages.enabled; then
  # One shown entry with and one without title, the rest must never be shown:
  # the current version, an invalid entry and a version after next.
  next="$(bump_version "$CURRENT_VERSION" "$(plan get build.next_version_bump)")"
  jq -n --arg current "$CURRENT_VERSION" --arg next "$next" --arg later "$(bump_version "$next" major)" '{messages: [
    {version: $current, title: "E2E current", message: "Must not be shown: this is the version before the update."},
    {version: $next, title: "E2E next", message: "Shown once when upgrading to v\($next).", unknownKey: true},
    {version: $next, message: "Second message for v\($next), without a title."},
    {version: $next, title: "E2E invalid", message: 42},
    {version: $later, title: "E2E later", message: "Must not be shown: this version is after the update."}
  ]}' >"$RUN/upgrade-messages-next.json"
  "$E2E_SCRIPTS/stage.sh" "$RUN" next --bump "$(plan get build.next_version_bump)" \
    --upgrade-messages "$RUN/upgrade-messages-next.json" >&2
  NEXT_VERSION="$(cat "$RUN/stage/next/.e2e_version")"
fi

PLAIN_VERSION=""
if plan enabled phases.upgrade_messages.enabled &&
  plan json | jq -e --arg host "$E2E_HOST" '.platforms as $p
    | [.upgrade_messages[]? | select(.enabled != false and .plain_build == true) | (.platforms // ["linux"])[]]
    | any(.[]; $p[.].enabled and $p[.].host == $host)' >/dev/null; then
  echo '{"messages": []}' >"$RUN/upgrade-messages-plain.json"
  bump="$(plan get build.next_version_bump)"
  "$E2E_SCRIPTS/stage.sh" "$RUN" plain --bump "$bump" --bump "$bump" \
    --upgrade-messages "$RUN/upgrade-messages-plain.json" >&2
  PLAIN_VERSION="$(cat "$RUN/stage/plain/.e2e_version")"
fi

PREVIOUS_TAG=""
if plan enabled phases.old_to_new_update.enabled; then
  PREVIOUS_TAG="$("$E2E_SCRIPTS/previous_release.sh" "$RUN")"
fi

warnings=()
if [ -n "$PREVIOUS_TAG" ] && [ "$PREVIOUS_TAG" = "v$CURRENT_VERSION" ]; then
  warnings+=("the build under test has the same version as the previous release ($PREVIOUS_TAG): bump pubspec.yaml, otherwise the old->new update test has nothing to update to")
  log "warning: ${warnings[0]}"
fi

# Only the platforms this host is responsible for.
platforms="$(plan json | jq -c --arg host "$E2E_HOST" '[.platforms | to_entries[] | select(.value.enabled and .value.host == $host) | .key]')"
phases="$(plan json | jq -c '[.phases | to_entries[] | select(.value.enabled) | .key]')"
dirty=false
git -C "$REPO_DIR" diff --quiet HEAD || dirty=true

jq -n \
  --arg id "$ID" --arg run "$RUN" --arg started "$STARTED" \
  --arg commit "$(git -C "$REPO_DIR" rev-parse --short HEAD)" --argjson dirty "$dirty" \
  --arg current "$CURRENT_VERSION" --arg next "$NEXT_VERSION" --arg plain "$PLAIN_VERSION" --arg previous "$PREVIOUS_TAG" \
  --arg host "$E2E_HOST" --argjson platforms "$platforms" --argjson phases "$phases" \
  --argjson warnings "$(printf '%s\n' ${warnings[@]+"${warnings[@]}"} | jq -R . | jq -sc 'map(select(length > 0))')" \
  --arg packages "$(cat "$RUN/stage/current/.e2e_packages/VERSIONS" 2>/dev/null || true)" \
  '{id: $id, runDir: $run, startedAt: $started, commit: $commit, uncommittedChanges: $dirty,
    versions: {previous: $previous, current: $current, next: $next, plain: $plain},
    localPackages: $packages, host: $host, platforms: $platforms, phases: $phases,
    warnings: $warnings}' >"$RUN/run.json"
cat "$RUN/run.json"
