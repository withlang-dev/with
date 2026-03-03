#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler binary for phase2 implicit-ok tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_run_pass() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>/dev/null; then
    echo "PASS(implicit-ok-run) $file"
  else
    echo "FAIL(implicit-ok-run) $file"
    failures=$((failures + 1))
  fi
}

expect_run_fail() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>/dev/null; then
    echo "FAIL(implicit-ok-run-fail) $file"
    failures=$((failures + 1))
  else
    echo "PASS(implicit-ok-run-fail) $file"
  fi
}

expect_check_fail_msg() {
  local file="$1"
  local msg="$2"
  local stderr_file="$tmpdir/stderr.fail.$$"
  if "$WITH_BIN" check "$file" >/dev/null 2>"$stderr_file"; then
    echo "FAIL(implicit-ok-check-fail) $file"
    failures=$((failures + 1))
  else
    if grep -Fq "$msg" "$stderr_file"; then
      echo "PASS(implicit-ok-check-fail) $file"
    else
      echo "FAIL(implicit-ok-check-fail-msg) $file"
      cat "$stderr_file"
      failures=$((failures + 1))
    fi
  fi
  rm -f "$stderr_file"
}

expect_dump_contains() {
  local file="$1"
  local needle="$2"
  local stdout_file="$tmpdir/stdout.dump.$$"
  local stderr_file="$tmpdir/stderr.dump.$$"
  if "$WITH_BIN" check "$file" --dump-ast >"$stdout_file" 2>"$stderr_file"; then
    if grep -Fq "$needle" "$stdout_file"; then
      echo "PASS(implicit-ok-dump) $file :: $needle"
    else
      echo "FAIL(implicit-ok-dump-missing) $file :: $needle"
      cat "$stdout_file"
      failures=$((failures + 1))
    fi
  else
    echo "FAIL(implicit-ok-dump-check) $file"
    cat "$stderr_file"
    failures=$((failures + 1))
  fi
  rm -f "$stdout_file" "$stderr_file"
}

cat >"$tmpdir/implicit_ok_value_tail_ok.w" <<'EOF1'
fn get -> Result[i32, i32]:
    42

fn main -> i32:
    if (get() ?? -1) == 42 then 0 else 1
EOF1
expect_run_pass "$tmpdir/implicit_ok_value_tail_ok.w"

cat >"$tmpdir/implicit_ok_with_try_ok.w" <<'EOF2'
error ParseError = Bad

fn parse(flag: bool) -> Result[i32, ParseError]:
    if flag then Ok(5) else Err(Bad)

fn compute(flag: bool) -> Result[i32, ParseError]:
    let v = parse(flag)?
    v + 3

fn main -> i32:
    let ok = compute(true)
    let err = compute(false)
    if (ok ?? -1) == 8 and err.is_err() then 0 else 1
EOF2
expect_run_pass "$tmpdir/implicit_ok_with_try_ok.w"

cat >"$tmpdir/implicit_ok_explicit_return_ok.w" <<'EOF3'
fn f -> Result[i32, i32]:
    return 7

fn main -> i32:
    let r = f()
    if r.is_ok() and (r ?? -1) == 7 then 0 else 1
EOF3
expect_run_pass "$tmpdir/implicit_ok_explicit_return_ok.w"

cat >"$tmpdir/implicit_ok_passthrough_result_ok.w" <<'EOF4'
fn source(flag: bool) -> Result[i32, i32]:
    if flag then Ok(9) else Err(2)

fn wrap(flag: bool) -> Result[i32, i32]:
    source(flag)

fn main -> i32:
    let a = wrap(true)
    let b = wrap(false)
    if a.is_ok() and b.is_err() and (a ?? -1) == 9 then 0 else 1
EOF4
expect_run_pass "$tmpdir/implicit_ok_passthrough_result_ok.w"

cat >"$tmpdir/implicit_ok_result_unit_empty_tail_ok.w" <<'EOF5'
fn touch -> Result[Unit, i32]:
    let x = 1
    let y = x + 2

fn main -> i32:
    let r = touch()
    if r.is_ok() then 0 else 1
EOF5
expect_run_pass "$tmpdir/implicit_ok_result_unit_empty_tail_ok.w"

cat >"$tmpdir/implicit_ok_non_unit_empty_tail_fail.w" <<'EOF6'
fn bad -> Result[i32, i32]:
    let x = 1

fn main -> i32:
    let _ = bad()
    0
EOF6
expect_run_fail "$tmpdir/implicit_ok_non_unit_empty_tail_fail.w"

cat >"$tmpdir/implicit_self_instance_ok.w" <<'EOF7'
type Counter = { value: i32 }

extend Counter:
    fn inc:
        self.value = self.value + 1

fn main -> i32:
    let c = Counter { value: 1 }
    c.inc()
    if c.value == 2 then 0 else 1
EOF7
expect_run_pass "$tmpdir/implicit_self_instance_ok.w"

cat >"$tmpdir/implicit_self_static_new_ok.w" <<'EOF8'
type S = { x: i32 }

extend S:
    fn new -> S:
        S { x: 1 }

fn main -> i32:
    let s = S.new()
    if s.x == 1 then 0 else 1
EOF8
expect_run_pass "$tmpdir/implicit_self_static_new_ok.w"

cat >"$tmpdir/implicit_self_read_only_ok.w" <<'EOF9'
type Counter = { value: i32 }

extend Counter:
    fn value -> i32:
        self.value

fn main -> i32:
    let c = Counter { value: 7 }
    if c.value() == 7 then 0 else 1
EOF9
expect_run_pass "$tmpdir/implicit_self_read_only_ok.w"

cat >"$tmpdir/implicit_self_explicit_receiver_ok.w" <<'EOF10'
type Counter = { value: i32 }

extend Counter:
    fn add(self: Counter, x: i32) -> i32:
        self.value + x

fn main -> i32:
    let c = Counter { value: 5 }
    if c.add(2) == 7 then 0 else 1
EOF10
expect_run_pass "$tmpdir/implicit_self_explicit_receiver_ok.w"

cat >"$tmpdir/implicit_self_mode_inference_dump.w" <<'EOF11'
type Counter = { value: i32 }

extend Counter:
    fn read -> i32:
        self.value

    fn inc:
        self.value = self.value + 1

    fn consume -> Counter:
        self

fn main -> i32:
    let c = Counter { value: 1 }
    let _ = c.read()
    c.inc()
    let _d = c.consume()
    0
EOF11
expect_dump_contains "$tmpdir/implicit_self_mode_inference_dump.w" "fn Counter.read(self: &Counter) -> i32:"
expect_dump_contains "$tmpdir/implicit_self_mode_inference_dump.w" "fn Counter.inc(mut self: &mut Counter):"
expect_dump_contains "$tmpdir/implicit_self_mode_inference_dump.w" "fn Counter.consume(self: Counter) -> Counter:"

cat >"$tmpdir/implicit_self_mode_conflict_fail.w" <<'EOF12'
type C = { value: i32 }

extend C:
    fn bad -> C:
        self.value = 1
        self

fn main -> i32:
    let c = C { value: 0 }
    let _ = c.bad()
    0
EOF12
expect_check_fail_msg "$tmpdir/implicit_self_mode_conflict_fail.w" "conflicting implicit self usage"

if [[ "$failures" -ne 0 ]]; then
  echo "phase2 implicit-ok tests: $failures failure(s)"
  exit 1
fi

echo "phase2 implicit-ok tests: PASS"
