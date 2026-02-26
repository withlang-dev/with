#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler binary for phase3 std.string tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_check_pass() {
  local file="$1"
  if "$WITH_BIN" check "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "PASS(std-string-check) $file"
  else
    echo "FAIL(std-string-check) $file"
    cat "$tmpdir/stderr.$$"
    failures=$((failures + 1))
  fi
  rm -f "$tmpdir/stderr.$$"
}

expect_run_pass() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "PASS(std-string-run) $file"
  else
    echo "FAIL(std-string-run) $file"
    cat "$tmpdir/stderr.$$"
    failures=$((failures + 1))
  fi
  rm -f "$tmpdir/stderr.$$"
}

expect_check_fail() {
  local file="$1"
  if "$WITH_BIN" check "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "FAIL(std-string-fail) $file"
    failures=$((failures + 1))
  else
    echo "PASS(std-string-fail) $file"
  fi
  rm -f "$tmpdir/stderr.$$"
}

expect_check_pass "lib/std/string.w"

expect_run_pass "test/cases/stdlib_string.w"
expect_run_pass "test/cases/stdlib_string_ops.w"
expect_run_pass "test/cases/string_methods.w"
expect_run_pass "test/cases/str_methods_adv.w"
expect_run_pass "test/cases/string_split.w"
expect_run_pass "test/cases/string_basic_ops.w"
expect_run_pass "test/cases/string_escape.w"

cat >"$tmpdir/std_string_wrappers_and_strview_ok.w" <<'EOF1'
use std.string

fn take_view(v: &str) -> i64 =
    view_len(v)

fn main() -> i32 =
    let a = "abc"
    let b = "abd"
    assert(string_cmp(a, b) < 0)
    assert(string_cmp(b, a) > 0)
    assert(string_cmp(a, "abc") == 0)

    assert(string_to_int("42") == 42)
    assert(string_to_int("0") == 0)
    assert(string_to_int("-7") == 0 - 7)

    assert(is_alpha(65))
    assert(not is_alpha(95))
    assert(is_digit(57))
    assert(not is_digit(65))
    assert(is_space(32))
    assert(is_space(10))
    assert(not is_space(65))

    let owned: str = "hello"
    let view: &str = &owned
    assert(take_view(view) == 5)
    assert(view_len(view) == owned.len())
    assert(not view_is_empty(view))
    assert(view_eq(view, view))
    0
EOF1
expect_run_pass "$tmpdir/std_string_wrappers_and_strview_ok.w"

cat >"$tmpdir/std_string_bad_len_arg_fail.w" <<'EOF2'
use std.string

fn main() -> i32 =
    let _n = string_len(123)
    0
EOF2
expect_check_fail "$tmpdir/std_string_bad_len_arg_fail.w"

cat >"$tmpdir/std_string_bad_alpha_arg_fail.w" <<'EOF3'
use std.string

fn main() -> i32 =
    let _ok = is_alpha("A")
    0
EOF3
expect_check_fail "$tmpdir/std_string_bad_alpha_arg_fail.w"

cat >"$tmpdir/std_string_bad_cmp_arity_fail.w" <<'EOF4'
use std.string

fn main() -> i32 =
    let _c = string_cmp("a")
    0
EOF4
expect_check_fail "$tmpdir/std_string_bad_cmp_arity_fail.w"

if [[ "$failures" -ne 0 ]]; then
  echo "phase3 std.string tests: $failures failure(s)"
  exit 1
fi

echo "phase3 std.string tests: PASS"
