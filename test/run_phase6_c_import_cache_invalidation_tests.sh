#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler/runtime for phase6 c_import cache invalidation tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

check_trace_counts() {
  local file="$1"
  local min_hits="$2"
  local min_misses="$3"

  local trace
  if ! trace=$(WITH_TRACE_CIMPORT_CACHE=1 "$WITH_BIN" check "$file" 2>&1 >/dev/null); then
    echo "FAIL(phase6-cimport-cache-check) $file"
    failures=$((failures + 1))
    return
  fi

  local hits
  local misses
  hits=$(printf '%s\n' "$trace" | grep -c "c_import cache hit" || true)
  misses=$(printf '%s\n' "$trace" | grep -c "c_import cache miss" || true)

  if [[ "$hits" -lt "$min_hits" || "$misses" -lt "$min_misses" ]]; then
    echo "FAIL(phase6-cimport-cache-counts) $file (hits=$hits misses=$misses)"
    failures=$((failures + 1))
    return
  fi

  echo "PASS(phase6-cimport-cache) $file (hits=$hits misses=$misses)"
}

# Baseline: same header + same link libs should hit cache.
cat >"$tmpdir/c_import_cache_same_links.w" <<'EOF1'
use c_import("int shared_fn(int);", link: "c")
use c_import("int shared_fn(int);", link: "c")

fn main() -> i32 = 0
EOF1
check_trace_counts "$tmpdir/c_import_cache_same_links.w" 1 1

# Invalidation: same header + different link libs should miss twice.
cat >"$tmpdir/c_import_cache_diff_links.w" <<'EOF2'
use c_import("int shared_fn(int);", link: "c")
use c_import("int shared_fn(int);", link: "m")

fn main() -> i32 = 0
EOF2
check_trace_counts "$tmpdir/c_import_cache_diff_links.w" 0 2

# Invalidation override knob should still produce deterministic behavior.
cat >"$tmpdir/c_import_cache_epoch_override.w" <<'EOF3'
use c_import("int epoch_fn(int);")
use c_import("int epoch_fn(int);")

fn main() -> i32 = 0
EOF3
epoch_trace=""
if ! epoch_trace=$(WITH_TRACE_CIMPORT_CACHE=1 WITH_CIMPORT_CACHE_EPOCH=phase6 "$WITH_BIN" check "$tmpdir/c_import_cache_epoch_override.w" 2>&1 >/dev/null); then
  echo "FAIL(phase6-cimport-cache-epoch-check)"
  failures=$((failures + 1))
else
  if printf '%s\n' "$epoch_trace" | grep -Fq "c_import cache hit" && printf '%s\n' "$epoch_trace" | grep -Fq "c_import cache miss"; then
    echo "PASS(phase6-cimport-cache-epoch)"
  else
    echo "FAIL(phase6-cimport-cache-epoch-trace)"
    printf '%s\n' "$epoch_trace"
    failures=$((failures + 1))
  fi
fi

if [[ "$failures" -ne 0 ]]; then
  echo "phase6 c_import cache invalidation tests: $failures failure(s)"
  exit 1
fi

echo "phase6 c_import cache invalidation tests: PASS"
