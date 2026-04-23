#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -eq 0 ]; then
  expected=""
else
  expected="$(printf '%s\n' "$@" | LC_ALL=C sort)"
fi
actual="$(find runtime -maxdepth 1 -type f -name '*.c' | LC_ALL=C sort)"

if [ "$actual" != "$expected" ]; then
  echo "error: runtime C file allowlist drifted" >&2
  echo "expected:" >&2
  if [ -n "$expected" ]; then
    printf '%s\n' "$expected" | sed 's/^/  /' >&2
  else
    echo "  <none>" >&2
  fi
  echo "actual:" >&2
  if [ -n "$actual" ]; then
    printf '%s\n' "$actual" | sed 's/^/  /' >&2
  else
    echo "  <none>" >&2
  fi
  exit 1
fi
