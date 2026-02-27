#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler binary for struct/field tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_check_pass() {
  local file="$1"
  if "$WITH_BIN" check "$file" >/dev/null 2>/dev/null; then
    echo "PASS(struct-pass) $file"
  else
    echo "FAIL(struct-pass) $file"
    failures=$((failures + 1))
  fi
}

expect_check_fail() {
  local file="$1"
  if "$WITH_BIN" check "$file" >/dev/null 2>/dev/null; then
    echo "FAIL(struct-negative) $file"
    failures=$((failures + 1))
  else
    echo "PASS(struct-negative) $file"
  fi
}

cat >"$tmpdir/struct_ok.w" <<'EOF'
type Point = { x: i32, y: i32 }

fn main -> i32:
    let p = Point { x: 1, y: 2 }
    p.x + p.y
EOF
expect_check_pass "$tmpdir/struct_ok.w"

cat >"$tmpdir/struct_field_type_mismatch.w" <<'EOF'
type Point = { x: i32, y: i32 }

fn main -> i32:
    let p = Point { x: true, y: 2 }
    p.x
EOF
expect_check_fail "$tmpdir/struct_field_type_mismatch.w"

cat >"$tmpdir/struct_unknown_field_access.w" <<'EOF'
type Point = { x: i32, y: i32 }

fn main -> i32:
    let p = Point { x: 1, y: 2 }
    p.z
EOF
expect_check_fail "$tmpdir/struct_unknown_field_access.w"

if [[ "$failures" -ne 0 ]]; then
  echo "phase0 struct/field tests: $failures failure(s)"
  exit 1
fi

echo "phase0 struct/field tests: PASS"

