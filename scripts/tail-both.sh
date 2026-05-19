#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
usage: scripts/tail-both.sh STDOUT_FILE STDERR_FILE [LINES]

Print labeled tails for paired stdout/stderr capture files.
USAGE
}

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  usage
  exit 0
fi

[[ "$#" -ge 2 && "$#" -le 3 ]] || { usage; exit 2; }

OUT_FILE="$1"
ERR_FILE="$2"
LINES="${3:-40}"

print_tail() {
  local label="$1"
  local path="$2"

  printf '==> %s (%s) <==\n' "$label" "$path"
  if [[ -f "$path" ]]; then
    tail -n "$LINES" "$path"
  else
    echo "(missing)"
  fi
}

print_tail stdout "$OUT_FILE"
print_tail stderr "$ERR_FILE"
