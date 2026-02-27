#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler binary for phase2 chained-if-let tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_run_pass() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>/dev/null; then
    echo "PASS(chained-if-let-run) $file"
  else
    echo "FAIL(chained-if-let-run) $file"
    failures=$((failures + 1))
  fi
}

expect_check_fail() {
  local file="$1"
  if "$WITH_BIN" check "$file" >/dev/null 2>/dev/null; then
    echo "FAIL(chained-if-let-fail) $file"
    failures=$((failures + 1))
  else
    echo "PASS(chained-if-let-fail) $file"
  fi
}

cat >"$tmpdir/chained_if_let_basic_ok.w" <<'EOF1'
type A = AVal(i32) | ANone
type B = BVal(i32) | BNone

fn sum(a: A, b: B) -> i32:
    if let AVal(x) = a, let BVal(y) = b:
        x + y
    else
        0

fn main -> i32:
    if sum(AVal(2), BVal(3)) == 5 and sum(AVal(1), BNone) == 0 then 0 else 1
EOF1
expect_run_pass "$tmpdir/chained_if_let_basic_ok.w"

cat >"$tmpdir/chained_if_let_mixed_bool_ok.w" <<'EOF2'
type User = User(i32, bool) | Missing
type Email = Addr(i32) | NoEmail

fn check(u: User, e: Email) -> i32:
    if let User(id, active) = u, active, let Addr(mid) = e:
        if id == mid then 7 else 3
    else
        0

fn main -> i32:
    let ok =
        check(User(4, true), Addr(4)) == 7 and
        check(User(4, false), Addr(4)) == 0 and
        check(User(4, true), NoEmail) == 0
    if ok then 0 else 1
EOF2
expect_run_pass "$tmpdir/chained_if_let_mixed_bool_ok.w"

cat >"$tmpdir/chained_if_let_syntax_fail.w" <<'EOF3'
type A = AVal(i32) | ANone
type B = BVal(i32) | BNone

fn main -> i32:
    let _x = if let AVal(a) = AVal(1), :
        a
    else
        0
    0
EOF3
expect_check_fail "$tmpdir/chained_if_let_syntax_fail.w"

if [[ "$failures" -ne 0 ]]; then
  echo "phase2 chained-if-let tests: $failures failure(s)"
  exit 1
fi

echo "phase2 chained-if-let tests: PASS"
