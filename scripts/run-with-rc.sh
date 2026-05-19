#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
usage: scripts/run-with-rc.sh [--tail N] OUT_PREFIX -- COMMAND [ARG...]

Run COMMAND, capturing:
  OUT_PREFIX.out     stdout
  OUT_PREFIX.err     stderr
  OUT_PREFIX.rc      numeric exit status

The script exits with COMMAND's status.
USAGE
}

TAIL_LINES=0

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --tail)
      [[ "$#" -ge 2 ]] || { usage; exit 2; }
      TAIL_LINES="$2"
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    --)
      echo "error: missing output prefix before --" >&2
      usage
      exit 2
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

[[ "$#" -ge 2 ]] || { usage; exit 2; }
OUT_PREFIX="$1"
shift
[[ "${1:-}" == "--" ]] || { usage; exit 2; }
shift
[[ "$#" -ge 1 ]] || { usage; exit 2; }

OUT_FILE="${OUT_PREFIX}.out"
ERR_FILE="${OUT_PREFIX}.err"
RC_FILE="${OUT_PREFIX}.rc"
mkdir -p "$(dirname "$OUT_PREFIX")"

set +e
"$@" >"$OUT_FILE" 2>"$ERR_FILE"
RC="$?"
set -e

printf '%s\n' "$RC" >"$RC_FILE"
printf 'rc=%s\nstdout=%s\nstderr=%s\n' "$RC" "$OUT_FILE" "$ERR_FILE"

if [[ "$TAIL_LINES" != "0" ]]; then
  scripts/tail-both.sh "$OUT_FILE" "$ERR_FILE" "$TAIL_LINES"
fi

exit "$RC"
