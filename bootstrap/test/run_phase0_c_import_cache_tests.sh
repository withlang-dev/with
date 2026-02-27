#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler binary for c_import cache tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

check_trace_counts() {
  local file="$1"
  local min_hits="$2"
  local min_misses="$3"
  local exact_hits="${4:-}"

  local trace
  if ! trace=$(WITH_TRACE_CIMPORT_CACHE=1 "$WITH_BIN" check "$file" 2>&1 >/dev/null); then
    echo "FAIL(c_import-cache-check) $file"
    failures=$((failures + 1))
    return
  fi

  local hits
  local misses
  hits=$(printf '%s\n' "$trace" | grep -c "c_import cache hit" || true)
  misses=$(printf '%s\n' "$trace" | grep -c "c_import cache miss" || true)

  if [[ "$hits" -lt "$min_hits" || "$misses" -lt "$min_misses" ]]; then
    echo "FAIL(c_import-cache-counts) $file (hits=$hits misses=$misses)"
    failures=$((failures + 1))
    return
  fi

  if [[ -n "$exact_hits" && "$hits" -ne "$exact_hits" ]]; then
    echo "FAIL(c_import-cache-exact-hits) $file (hits=$hits expected=$exact_hits)"
    failures=$((failures + 1))
    return
  fi

  echo "PASS(c_import-cache) $file (hits=$hits misses=$misses)"
}

cat >"$tmpdir/c_import_cache_same.w" <<'EOF1'
use c_import("int same_fn(int);")
use c_import("int same_fn(int);")

fn main -> i32:
    0
EOF1
check_trace_counts "$tmpdir/c_import_cache_same.w" 1 1

cat >"$tmpdir/c_import_cache_invalidate.w" <<'EOF2'
use c_import("int one_fn(int);")
use c_import("int two_fn(int);")

fn main -> i32:
    0
EOF2
check_trace_counts "$tmpdir/c_import_cache_invalidate.w" 0 2 0

cat >"$tmpdir/mod_a.w" <<'EOF3'
use c_import("int shared_fn(int);")

fn a -> i32:
    1
EOF3

cat >"$tmpdir/mod_b.w" <<'EOF4'
use c_import("int shared_fn(int);")

fn b -> i32:
    2
EOF4

cat >"$tmpdir/c_import_cache_imports.w" <<'EOF5'
use mod_a
use mod_b

fn main -> i32:
    if a() + b() == 3 then 0 else 1
EOF5
check_trace_counts "$tmpdir/c_import_cache_imports.w" 1 1

if [[ "$failures" -ne 0 ]]; then
  echo "phase0 c_import cache tests: $failures failure(s)"
  exit 1
fi

echo "phase0 c_import cache tests: PASS"
