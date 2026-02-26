#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler/runtime for phase5 stdlib trait-impl coverage tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_run_pass() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "PASS(stdlib-trait-run) $file"
  else
    echo "FAIL(stdlib-trait-run) $file"
    cat "$tmpdir/stderr.$$"
    failures=$((failures + 1))
  fi
  rm -f "$tmpdir/stderr.$$"
}

expect_run_fail() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "FAIL(stdlib-trait-run-fail) $file"
    failures=$((failures + 1))
  else
    echo "PASS(stdlib-trait-run-fail) $file"
  fi
  rm -f "$tmpdir/stderr.$$"
}

expect_check_fail_msg() {
  local file="$1"
  local msg="$2"
  local stderr_file="$tmpdir/stderr.err.$$"
  if "$WITH_BIN" check "$file" >/dev/null 2>"$stderr_file"; then
    echo "FAIL(stdlib-trait-check-fail) $file"
    failures=$((failures + 1))
  else
    if grep -Fq "$msg" "$stderr_file"; then
      echo "PASS(stdlib-trait-check-fail) $file"
    else
      echo "FAIL(stdlib-trait-check-msg) $file"
      cat "$stderr_file"
      failures=$((failures + 1))
    fi
  fi
  rm -f "$stderr_file"
}

# Vec coverage: iteration + index operator.
cat >"$tmpdir/vec_iter_index_ok.w" <<'EOF1'
fn main() -> i32 =
    let v = Vec.of(1, 2, 3, 4)
    var sum = 0
    for x in v:
        sum = sum + x
    assert(sum == 10)
    assert(v[1] == 2)
    0
EOF1
expect_run_pass "$tmpdir/vec_iter_index_ok.w"

# HashMap coverage: index operator for present key.
cat >"$tmpdir/hashmap_index_ok.w" <<'EOF2'
fn main() -> i32 =
    let m = HashMap.new()
    m.insert("a", 3)
    m.insert("b", 7)
    assert(m["a"] == 3)
    assert(m["b"] == 7)
    0
EOF2
expect_run_pass "$tmpdir/hashmap_index_ok.w"

# HashMap index on missing key is non-happy-path and should fail at runtime.
cat >"$tmpdir/hashmap_index_missing_fail.w" <<'EOF3'
fn main() -> i32 =
    let m = HashMap.new()
    m.insert("a", 1)
    let _ = m["missing"]
    0
EOF3
expect_run_fail "$tmpdir/hashmap_index_missing_fail.w"

# Result/Try coverage: `?` over Result path.
cat >"$tmpdir/result_try_ok.w" <<'EOF4'
fn step(x: i32) -> Result[i32, i32] =
    Ok(x + 1)

fn run() -> Result[i32, i32] =
    let a = step(4)?
    a * 2

fn main() -> i32 =
    assert(run().unwrap() == 10)
    0
EOF4
expect_run_pass "$tmpdir/result_try_ok.w"

# Guard/scoped coverage via std.sync guard methods.
cat >"$tmpdir/sync_guard_scoped_ok.w" <<'EOF5'
use std.sync

fn main() -> i32 =
    let m = mutex_new(9)
    let r = with m as g:
        g.value
    let r2 = with m as mut g:
        g.value + 1
    assert(r == 9)
    assert(r2 == 10)
    0
EOF5
expect_run_pass "$tmpdir/sync_guard_scoped_ok.w"

# String coverage: `+` and display-ish formatting path via println.
cat >"$tmpdir/string_add_display_ok.w" <<'EOF6'
fn main() -> i32 =
    let a = "ab"
    let b = "cd"
    let c = a + b
    assert(c.len() == 4)
    println(c)
    0
EOF6
expect_run_pass "$tmpdir/string_add_display_ok.w"

# Non-happy-path: invalid String add operand type.
cat >"$tmpdir/string_add_mismatch_fail.w" <<'EOF7'
fn main() -> i32 =
    let a = "x"
    let n = 1
    let _ = a + n
    0
EOF7
expect_check_fail_msg "$tmpdir/string_add_mismatch_fail.w" "arithmetic operator requires numeric operands"

# Non-happy-path: `?` on non-Result/Option.
cat >"$tmpdir/try_non_result_fail.w" <<'EOF8'
fn bad() -> i32 =
    let x = 1
    x?

fn main() -> i32 = 0
EOF8
expect_check_fail_msg "$tmpdir/try_non_result_fail.w" "? operator requires Option or Result"

if [[ "$failures" -ne 0 ]]; then
  echo "phase5 stdlib trait-impl coverage tests: $failures failure(s)"
  exit 1
fi

echo "phase5 stdlib trait-impl coverage tests: PASS"
