#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
usage: scripts/build-action-debug.sh [--compiler PATH] [--break NAME] TARGET [-- ARGS...]

Run `with build TARGET` under lldb. TARGET may be written with or without the
leading colon. Extra ARGS are passed after the target.

examples:
  scripts/build-action-debug.sh :emit-c-test
  scripts/build-action-debug.sh --break bs_fail pcre2-migrate -- --no-deps
USAGE
}

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMPILER="${WITH_DEBUG_COMPILER:-${WITH:-${ROOT_DIR}/out/bin/with}}"
BREAKPOINTS=()

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --compiler)
      [[ "$#" -ge 2 ]] || { usage; exit 2; }
      COMPILER="$2"
      shift 2
      ;;
    --break|-b)
      [[ "$#" -ge 2 ]] || { usage; exit 2; }
      BREAKPOINTS+=("$2")
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    --)
      shift
      break
      ;;
    -*)
      echo "error: unknown option: $1" >&2
      usage
      exit 2
      ;;
    *)
      break
      ;;
  esac
done

[[ "$#" -ge 1 ]] || { usage; exit 2; }

TARGET="$1"
shift
if [[ "$TARGET" != :* ]]; then
  TARGET=":${TARGET}"
fi

if [[ ! -x "$COMPILER" ]]; then
  echo "error: compiler is not executable: $COMPILER" >&2
  exit 1
fi

lldb_args=()
for bp in "${BREAKPOINTS[@]}"; do
  lldb_args+=("-o" "breakpoint set --name ${bp}")
done

cd "$ROOT_DIR"
exec lldb "${lldb_args[@]}" -- "$COMPILER" build "$TARGET" "$@"
