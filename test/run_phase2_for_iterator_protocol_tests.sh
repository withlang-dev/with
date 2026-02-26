#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler binary for phase2 for-iterator-protocol tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_run_pass() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "PASS(for-iter-run) $file"
  else
    echo "FAIL(for-iter-run) $file"
    cat "$tmpdir/stderr.$$"
    failures=$((failures + 1))
  fi
  rm -f "$tmpdir/stderr.$$"
}

expect_build_fail_msg() {
  local file="$1"
  local msg="$2"
  if "$WITH_BIN" build "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "FAIL(for-iter-fail) $file"
    failures=$((failures + 1))
  else
    if grep -Fq "$msg" "$tmpdir/stderr.$$"; then
      echo "PASS(for-iter-fail) $file"
    else
      echo "FAIL(for-iter-fail-msg) $file"
      cat "$tmpdir/stderr.$$"
      failures=$((failures + 1))
    fi
  fi
  rm -f "$tmpdir/stderr.$$"
}

expect_build_fail() {
  local file="$1"
  if "$WITH_BIN" build "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "FAIL(for-iter-fail) $file"
    failures=$((failures + 1))
  else
    echo "PASS(for-iter-fail) $file"
  fi
  rm -f "$tmpdir/stderr.$$"
}

cat >"$tmpdir/for_iter_range_ok.w" <<'EOF1'
fn main() -> i32 =
    var sum = 0
    for i in 0..4:
        sum += i
    assert(sum == 6)
    0
EOF1
expect_run_pass "$tmpdir/for_iter_range_ok.w"

cat >"$tmpdir/for_iter_vec_ok.w" <<'EOF2'
fn main() -> i32 =
    let items = Vec.of(1, 2, 3)
    var sum = 0
    for x in items:
        sum += x
    assert(sum == 6)
    assert(items.len() == 3)
    0
EOF2
expect_run_pass "$tmpdir/for_iter_vec_ok.w"

cat >"$tmpdir/for_iter_custom_next_ok.w" <<'EOF3'
type CounterIter = { current: i32, end_val: i32 }

impl CounterIter =
    fn next(self: *mut CounterIter) -> ?i32 =
        if self.current < self.end_val:
            let v = self.current
            self.current = self.current + 1
            Some(v)
        else
            None

fn main() -> i32 =
    var it = CounterIter { current: 2, end_val: 6 }
    var sum = 0
    for x in it:
        sum += x
    assert(sum == 14)
    0
EOF3
expect_run_pass "$tmpdir/for_iter_custom_next_ok.w"

cat >"$tmpdir/for_iter_auto_insert_ok.w" <<'EOF4'
type CounterIter = { current: i32, end_val: i32 }

impl CounterIter =
    fn next(self: *mut CounterIter) -> ?i32 =
        if self.current < self.end_val:
            let v = self.current
            self.current = self.current + 1
            Some(v)
        else
            None

type CounterSet = { start: i32, stop: i32 }

impl CounterSet =
    fn iter(self: CounterSet) -> CounterIter =
        CounterIter { current: self.start, end_val: self.stop }

fn main() -> i32 =
    let c = CounterSet { start: 1, stop: 5 }
    var sum = 0
    for x in c:
        sum += x
    assert(sum == 10)
    0
EOF4
expect_run_pass "$tmpdir/for_iter_auto_insert_ok.w"

cat >"$tmpdir/for_iter_explicit_iter_ok.w" <<'EOF5'
type CounterIter = { current: i32, end_val: i32 }

impl CounterIter =
    fn next(self: *mut CounterIter) -> ?i32 =
        if self.current < self.end_val:
            let v = self.current
            self.current = self.current + 1
            Some(v)
        else
            None

type CounterSet = { start: i32, stop: i32 }

impl CounterSet =
    fn iter(self: CounterSet) -> CounterIter =
        CounterIter { current: self.start, end_val: self.stop }

fn main() -> i32 =
    let c = CounterSet { start: 3, stop: 7 }
    var sum = 0
    for x in c.iter():
        sum += x
    assert(sum == 18)
    0
EOF5
expect_run_pass "$tmpdir/for_iter_explicit_iter_ok.w"

cat >"$tmpdir/for_iter_expr_ok.w" <<'EOF6'
type CounterIter = { current: i32, end_val: i32 }

impl CounterIter =
    fn next(self: *mut CounterIter) -> ?i32 =
        if self.current < self.end_val:
            let v = self.current
            self.current = self.current + 1
            Some(v)
        else
            None

fn make_iter() -> CounterIter =
    CounterIter { current: 0, end_val: 4 }

fn main() -> i32 =
    var sum = 0
    for x in make_iter():
        sum += x
    assert(sum == 6)
    0
EOF6
expect_run_pass "$tmpdir/for_iter_expr_ok.w"

cat >"$tmpdir/for_iter_bad_next_fail.w" <<'EOF7'
type BadIter = { x: i32 }

impl BadIter =
    fn next(self: *mut BadIter) -> i32 =
        self.x

fn main() -> i32 =
    var it = BadIter { x: 1 }
    for x in it:
        let y = x
    0
EOF7
expect_build_fail "$tmpdir/for_iter_bad_next_fail.w"

cat >"$tmpdir/for_iter_non_iterable_fail.w" <<'EOF8'
fn main() -> i32 =
    for x in 7:
        let y = x
    0
EOF8
expect_build_fail "$tmpdir/for_iter_non_iterable_fail.w"

if [[ "$failures" -ne 0 ]]; then
  echo "phase2 for-iterator-protocol tests: $failures failure(s)"
  exit 1
fi

echo "phase2 for-iterator-protocol tests: PASS"
