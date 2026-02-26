#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler binary for phase2 field-shorthand tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_run_pass() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>/dev/null; then
    echo "PASS(field-shorthand-run) $file"
  else
    echo "FAIL(field-shorthand-run) $file"
    failures=$((failures + 1))
  fi
}

expect_check_fail() {
  local file="$1"
  if "$WITH_BIN" check "$file" >/dev/null 2>/dev/null; then
    echo "FAIL(field-shorthand-fail) $file"
    failures=$((failures + 1))
  else
    echo "PASS(field-shorthand-fail) $file"
  fi
}

cat >"$tmpdir/field_shorthand_struct_ok.w" <<'EOF1'
type User = { id: i32, active: bool, score: i32 }

fn main() -> i32 =
    let id = 7
    let score = 42
    let u = User { id, active: true, score }
    if u.id == 7 and u.active and u.score == 42 then 0 else 1
EOF1
expect_run_pass "$tmpdir/field_shorthand_struct_ok.w"

cat >"$tmpdir/field_shorthand_update_ok.w" <<'EOF2'
type Pair = { a: i32, b: i32 }

fn main() -> i32 =
    let a = 9
    let p = Pair { a: 1, b: 2 }
    let out = { p with a }
    if out.a == 9 and out.b == 2 then 0 else 1
EOF2
expect_run_pass "$tmpdir/field_shorthand_update_ok.w"

cat >"$tmpdir/field_shorthand_missing_binding_fail.w" <<'EOF3'
type User = { id: i32, active: bool }

fn main() -> i32 =
    let _u = User { id, active: true }
    0
EOF3
expect_check_fail "$tmpdir/field_shorthand_missing_binding_fail.w"

cat >"$tmpdir/field_shorthand_unknown_field_fail.w" <<'EOF4'
type Pair = { a: i32, b: i32 }

fn main() -> i32 =
    let c = 10
    let p = Pair { a: 1, b: 2 }
    let _bad = { p with c }
    0
EOF4
expect_check_fail "$tmpdir/field_shorthand_unknown_field_fail.w"

if [[ "$failures" -ne 0 ]]; then
  echo "phase2 field-shorthand tests: $failures failure(s)"
  exit 1
fi

echo "phase2 field-shorthand tests: PASS"
