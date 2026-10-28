#!/usr/bin/env bash
# Usage: tool/test/scripts/fake_github.sh <command> <run> <platform> [args...]
#
# One fake GitHub server per platform of a run (harness/bin/fake_github.dart),
# serving <run>/releases/<tag>/ as releases and <run>/contents/<tag>/ as the
# repository files at those tags.
#
#   start <run> <platform> <tag>...  start serving these releases, prints the
#                                    base URL as seen from the platform's VM /
#                                    emulator (pass it to the app)
#   serve <run> <platform> <tag>...  switch the served releases (no restart),
#                                    resets the repository files
#   contents <run> <platform> <tag> <path> <file>|none
#                                    serve <file> as the repository file <path>
#                                    at <tag>, none makes it 404
#   requests <run> <platform>        requests the app made so far (JSON lines)
#   stop <run> <platform>
#
# Tags are release directory names like v0.7.0 (see <run>/releases).
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

CMD="${1:?usage: fake_github.sh <command> <run> <platform> [args...]}"
RUN="$(run_dir "${2:?run required}")"
PLATFORM="${3:?platform required}"
shift 3
ROOT="$RUN/fake-github/$PLATFORM"
STATE="$RUN/env/fake-github-$PLATFORM.env"

serve() {
  rm -rf "$ROOT"
  mkdir -p "$ROOT"
  for tag in "$@"; do
    [ -d "$RUN/releases/$tag" ] || die "no release $tag in $RUN/releases"
    ln -s "$RUN/releases/$tag" "$ROOT/$tag"
    if [ -d "$RUN/contents/$tag" ]; then
      # Copied, so the contents command doesn't change other platforms' files.
      mkdir -p "$ROOT/.contents"
      cp -R "$RUN/contents/$tag" "$ROOT/.contents/$tag"
    fi
  done
  log "serving ${*:-no releases} to $PLATFORM"
}

case "$CMD" in
  start)
    [ -f "$STATE" ] && "$0" stop "$RUN" "$PLATFORM"
    serve "$@"
    # Bind only where the platform's environment can reach the host: tart's
    # bridge for the macOS VM, Docker's bridge for the Linux desktop
    # container, loopback for the Android emulator (its 10.0.2.2).
    case "$PLATFORM" in
      macos)
        bind="$(ifconfig bridge100 2>/dev/null | awk '/inet /{print $2; exit}')"
        bind="${bind:-192.168.64.1}"
        guest_host="$bind"
        ;;
      linux)
        bind="$(docker network inspect bridge -f '{{(index .IPAM.Config 0).Gateway}}' 2>/dev/null)"
        bind="${bind:-172.17.0.1}"
        guest_host=host.docker.internal
        ;;
      android) bind=127.0.0.1 guest_host=10.0.2.2 ;;
      *) bind=127.0.0.1 guest_host=127.0.0.1 ;;
    esac
    port=$((18000 + RANDOM % 2000))
    mkdir -p "$RUN/logs" "$RUN/env"
    e2e_tool fake_github --help >/dev/null # compile before backgrounding
    nohup "$(e2e_tool_path fake_github)" --root "$ROOT" --host "$bind" --port "$port" \
      --log "$RUN/logs/fake-github-$PLATFORM.jsonl" >"$RUN/logs/fake-github-$PLATFORM.log" 2>&1 &
    pid=$!
    sleep 1
    kill -0 "$pid" 2>/dev/null || die "fake GitHub did not start, see $RUN/logs/fake-github-$PLATFORM.log"
    {
      echo "PID=$pid"
      echo "URL=http://$guest_host:$port"
    } >"$STATE"
    echo "http://$guest_host:$port"
    ;;
  serve)
    serve "$@"
    ;;
  contents)
    tag="${1:?tag required}"
    path="${2:?repository path required}"
    src="${3:?file or none required}"
    [[ "$tag/$path" != *..* ]] || die "bad path $tag/$path"
    dest="$ROOT/.contents/$tag/$path"
    if [ "$src" = "none" ]; then
      rm -f "$dest"
      log "$path at $tag now 404s for $PLATFORM"
    else
      [ -f "$src" ] || die "no file $src"
      mkdir -p "$(dirname "$dest")"
      cp "$src" "$dest"
      log "serving $src as $path at $tag to $PLATFORM"
    fi
    ;;
  requests)
    cat "$RUN/logs/fake-github-$PLATFORM.jsonl" 2>/dev/null || true
    ;;
  stop)
    if [ -f "$STATE" ]; then
      # shellcheck disable=SC1090
      source "$STATE"
      kill "$PID" 2>/dev/null || true
      rm -f "$STATE"
    fi
    ;;
  *)
    die "unknown command $CMD"
    ;;
esac
