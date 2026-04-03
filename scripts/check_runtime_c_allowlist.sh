#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -eq 0 ]; then
  echo "usage: $0 runtime/file1.c [runtime/file2.c ...]" >&2
  exit 1
fi

expected="$(printf '%s\n' "$@" | LC_ALL=C sort)"
actual="$(find runtime -maxdepth 1 -type f -name '*.c' | LC_ALL=C sort)"

if [ "$actual" != "$expected" ]; then
  echo "error: runtime C file allowlist drifted" >&2
  echo "expected:" >&2
  printf '  %s\n' "$expected" >&2
  echo "actual:" >&2
  printf '  %s\n' "$actual" >&2
  exit 1
fi
