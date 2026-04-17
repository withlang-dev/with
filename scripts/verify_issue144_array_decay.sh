#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
WITH_BIN="${WITH_BIN:-$ROOT_DIR/out/bin/with}"
SRC="$ROOT_DIR/test/migrate/issue144_array_decay_compare.c"
TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/with-issue144.XXXXXX")"
trap 'rm -rf "$TMP_DIR"' EXIT

OUT="$TMP_DIR/issue144_array_decay_compare.w"
"$WITH_BIN" migrate "$SRC" -o "$OUT" --no-c-export >/dev/null

if ! grep -Eq 'parsed_pattern.*!=.*\(&stack_parsed_pattern.*\[0\] as \*mut' "$OUT"; then
    echo "FAIL: parsed_pattern comparison did not decay stack_parsed_pattern" >&2
    sed -n '/parsed_pattern/,+2p' "$OUT" >&2
    exit 1
fi

if ! grep -Eq 'groupinfo.*!=.*\(&stack_groupinfo.*\[0\] as \*mut' "$OUT"; then
    echo "FAIL: groupinfo comparison did not decay stack_groupinfo" >&2
    sed -n '/groupinfo/,+2p' "$OUT" >&2
    exit 1
fi

if grep -Eq 'parsed_pattern.*!= stack_parsed_pattern|groupinfo.*!= stack_groupinfo' "$OUT"; then
    echo "FAIL: raw pointer-vs-array comparison remains" >&2
    grep -En 'parsed_pattern.*!=|groupinfo.*!=' "$OUT" >&2
    exit 1
fi

if ! grep -Eq '\(&mirror_array.*\[0\] as \*mut.*\).*!=.*mirror_ptr' "$OUT"; then
    echo "FAIL: array-vs-pointer comparison did not decay mirror_array" >&2
    sed -n '/mirror_array/,+8p' "$OUT" >&2
    exit 1
fi

if ! grep -Eq '\(&lhs_array.*\[0\] as \*mut.*\).*!=.*\(&rhs_array.*\[0\] as \*mut' "$OUT"; then
    echo "FAIL: array-vs-array comparison did not decay both operands" >&2
    sed -n '/lhs_array/,+8p' "$OUT" >&2
    exit 1
fi

echo "VERIFIED: issue144 array operands decay in migrated comparisons"
