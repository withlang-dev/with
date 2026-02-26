#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler binary for phase1 disjoint-field borrow tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_check_pass() {
  local file="$1"
  if "$WITH_BIN" check "$file" >/dev/null 2>/dev/null; then
    echo "PASS(disjoint-pass) $file"
  else
    echo "FAIL(disjoint-pass) $file"
    failures=$((failures + 1))
  fi
}

expect_check_fail_msg() {
  local file="$1"
  local msg="$2"
  local out
  if out=$("$WITH_BIN" check "$file" 2>&1 >/dev/null); then
    echo "FAIL(disjoint-fail) $file"
    failures=$((failures + 1))
    return
  fi
  if [[ "$out" != *"$msg"* ]]; then
    echo "FAIL(disjoint-msg) $file"
    failures=$((failures + 1))
    return
  fi
  echo "PASS(disjoint-fail) $file"
}

cat >"$tmpdir/disjoint_fields_ok.w" <<'EOF1'
type Pair = { x: i32, y: i32 }

fn main -> i32:
    var p = Pair { x: 1, y: 2 }
    let rx = &p.x
    let ry = &mut p.y
    *ry = *ry + 1
    *rx + *ry
EOF1
expect_check_pass "$tmpdir/disjoint_fields_ok.w"

cat >"$tmpdir/same_field_conflict_fail.w" <<'EOF2'
type Pair = { x: i32, y: i32 }

fn main -> i32:
    var p = Pair { x: 1, y: 2 }
    let rx = &p.x
    let mx = &mut p.x
    *rx + *mx
EOF2
expect_check_fail_msg "$tmpdir/same_field_conflict_fail.w" "cannot borrow mutably: already borrowed"

cat >"$tmpdir/whole_place_conflict_fail.w" <<'EOF3'
type Pair = { x: i32, y: i32 }

fn main -> i32:
    var p = Pair { x: 1, y: 2 }
    let all = &mut p
    let fx = &p.x
    let _k = all.y
    *fx
EOF3
expect_check_fail_msg "$tmpdir/whole_place_conflict_fail.w" "cannot borrow: already mutably borrowed"

if [[ "$failures" -ne 0 ]]; then
  echo "phase1 disjoint-field borrow tests: $failures failure(s)"
  exit 1
fi

echo "phase1 disjoint-field borrow tests: PASS"
