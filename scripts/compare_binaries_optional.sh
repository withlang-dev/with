#!/usr/bin/env bash
set -euo pipefail

# Optional binary comparison between two compiler binaries.
# Usage: compare_binaries_optional.sh <binary_a> <binary_b>
#
# Compares SHA-256 hashes. If different, diffs symbol tables via nm -g.
# Reports PASS (identical) or INFO (divergent with diff summary).
# Non-blocking — always exits 0.

BINARY_A="${1:?usage: compare_binaries_optional.sh <binary_a> <binary_b>}"
BINARY_B="${2:?usage: compare_binaries_optional.sh <binary_a> <binary_b>}"

if [[ ! -f "$BINARY_A" ]]; then
  echo "INFO(fixpoint-binary) missing binary_a: $BINARY_A"
  exit 0
fi
if [[ ! -f "$BINARY_B" ]]; then
  echo "INFO(fixpoint-binary) missing binary_b: $BINARY_B"
  exit 0
fi

hash_a="$(shasum -a 256 "$BINARY_A" | awk '{print $1}')"
hash_b="$(shasum -a 256 "$BINARY_B" | awk '{print $1}')"

if [[ "$hash_a" == "$hash_b" ]]; then
  echo "PASS(fixpoint-binary) SHA-256 identical"
  echo "  hash: $hash_a"
  exit 0
fi

echo "INFO(fixpoint-binary) SHA-256 differs"
echo "  stage2: $hash_a"
echo "  stage3: $hash_b"

size_a="$(wc -c < "$BINARY_A" | tr -d ' ')"
size_b="$(wc -c < "$BINARY_B" | tr -d ' ')"
echo "  size: stage2=${size_a} stage3=${size_b}"

# Compare symbol tables if nm is available
if command -v nm >/dev/null 2>&1; then
  tmpdir="$(mktemp -d)"
  nm -g "$BINARY_A" 2>/dev/null | sort > "$tmpdir/syms_a.txt" || true
  nm -g "$BINARY_B" 2>/dev/null | sort > "$tmpdir/syms_b.txt" || true

  sym_diff="$(diff -u "$tmpdir/syms_a.txt" "$tmpdir/syms_b.txt" 2>/dev/null || true)"
  if [[ -z "$sym_diff" ]]; then
    echo "  symbols: identical (binary differs only in non-symbol data)"
  else
    added="$(echo "$sym_diff" | grep -c '^+[^+]' || true)"
    removed="$(echo "$sym_diff" | grep -c '^-[^-]' || true)"
    echo "  symbols: +${added} -${removed} lines differ"
  fi
  rm -rf "$tmpdir"
fi

exit 0
