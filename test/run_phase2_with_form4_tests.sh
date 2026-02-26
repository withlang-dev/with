#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler binary for phase2 with-form4 tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_run_pass() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>/dev/null; then
    echo "PASS(with-form4-run) $file"
  else
    echo "FAIL(with-form4-run) $file"
    failures=$((failures + 1))
  fi
}

expect_build_fail() {
  local file="$1"
  if "$WITH_BIN" build "$file" >/dev/null 2>/dev/null; then
    echo "FAIL(with-form4-fail) $file"
    failures=$((failures + 1))
  else
    echo "PASS(with-form4-fail) $file"
  fi
}

cat >"$tmpdir/with_form4_update_ok.w" <<'EOF1'
type Vec3 = { x: i32, y: i32, z: i32 }

fn main -> i32:
    let base = Vec3 { x: 1, y: 2, z: 3 }
    let moved = { base with x: base.x + 10, y: base.y + 20 }
    if moved.x == 11 and moved.y == 22 and moved.z == 3 then 0 else 1
EOF1
expect_run_pass "$tmpdir/with_form4_update_ok.w"

cat >"$tmpdir/with_form4_unknown_field_fail.w" <<'EOF2'
type Vec3 = { x: i32, y: i32, z: i32 }

fn main -> i32:
    let base = Vec3 { x: 1, y: 2, z: 3 }
    let _bad = { base with w: 99 }
EOF2
expect_build_fail "$tmpdir/with_form4_unknown_field_fail.w"

cat >"$tmpdir/with_form4_type_mismatch_fail.w" <<'EOF3'
type Vec3 = { x: i32, y: i32, z: i32 }

fn main -> i32:
    let base = Vec3 { x: 1, y: 2, z: 3 }
    let _bad = { base with x: true }
EOF3
expect_build_fail "$tmpdir/with_form4_type_mismatch_fail.w"

if [[ "$failures" -ne 0 ]]; then
  echo "phase2 with-form4 tests: $failures failure(s)"
  exit 1
fi

echo "phase2 with-form4 tests: PASS"
