#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
usage: scripts/diff-baseline.sh EXPECTED ACTUAL

Compare two files or two directories. Files use unified diff; directories use
recursive diff. Exits with diff's status.
USAGE
}

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  usage
  exit 0
fi

[[ "$#" -eq 2 ]] || { usage; exit 2; }

EXPECTED="$1"
ACTUAL="$2"

if [[ ! -e "$EXPECTED" ]]; then
  echo "error: expected path does not exist: $EXPECTED" >&2
  exit 2
fi

if [[ ! -e "$ACTUAL" ]]; then
  echo "error: actual path does not exist: $ACTUAL" >&2
  exit 2
fi

if [[ -d "$EXPECTED" || -d "$ACTUAL" ]]; then
  if [[ ! -d "$EXPECTED" || ! -d "$ACTUAL" ]]; then
    echo "error: both paths must be directories for recursive diff" >&2
    exit 2
  fi
  exec diff -ru "$EXPECTED" "$ACTUAL"
fi

exec diff -u --label "expected:$EXPECTED" --label "actual:$ACTUAL" "$EXPECTED" "$ACTUAL"
