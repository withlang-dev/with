#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler/runtime for phase5 Box[dyn]/&dyn tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_run_pass() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "PASS(box-ref-dyn-run) $file"
  else
    echo "FAIL(box-ref-dyn-run) $file"
    cat "$tmpdir/stderr.$$"
    failures=$((failures + 1))
  fi
  rm -f "$tmpdir/stderr.$$"
}

expect_check_fail_msg() {
  local file="$1"
  local msg="$2"
  local stderr_file="$tmpdir/stderr.err.$$"
  if "$WITH_BIN" check "$file" >/dev/null 2>"$stderr_file"; then
    echo "FAIL(box-ref-dyn-check-fail) $file"
    failures=$((failures + 1))
  else
    if grep -Fq "$msg" "$stderr_file"; then
      echo "PASS(box-ref-dyn-check-fail) $file"
    else
      echo "FAIL(box-ref-dyn-check-msg) $file"
      cat "$stderr_file"
      failures=$((failures + 1))
    fi
  fi
  rm -f "$stderr_file"
}

# Positive: explicit &T -> &dyn Trait coercion and method dispatch.
cat >"$tmpdir/ref_dyn_dispatch_ok.w" <<'EOF1'
trait Speak =
    fn speak(self: Self) -> i32

type Dog = { n: i32 }

impl Speak for Dog =
    fn speak(self: Dog) -> i32 = self.n

fn call_ref(x: &dyn Speak) -> i32 =
    x.speak()

fn main() -> i32 =
    let d = Dog { n: 7 }
    assert(call_ref(&d) == 7)
    let r = &d
    assert(call_ref(r) == 7)
    0
EOF1
expect_run_pass "$tmpdir/ref_dyn_dispatch_ok.w"

# Positive: concrete value -> Box[dyn Trait] coercion and dynamic dispatch.
cat >"$tmpdir/box_dyn_dispatch_ok.w" <<'EOF2'
trait Speak =
    fn speak(self: Self) -> i32

type Dog = { n: i32 }
type Cat = { n: i32 }

impl Speak for Dog =
    fn speak(self: Dog) -> i32 = self.n

impl Speak for Cat =
    fn speak(self: Cat) -> i32 = self.n * 2

fn call_box(x: Box[dyn Speak]) -> i32 =
    x.speak()

fn main() -> i32 =
    let d = Dog { n: 9 }
    let c = Cat { n: 5 }
    assert(call_box(d) == 9)
    assert(call_box(c) == 10)
    0
EOF2
expect_run_pass "$tmpdir/box_dyn_dispatch_ok.w"

# Negative: non-implementor cannot coerce to &dyn Trait.
cat >"$tmpdir/ref_dyn_missing_impl_fail.w" <<'EOF3'
trait Speak =
    fn speak(self: Self) -> i32

type Rock = { n: i32 }

fn call_ref(x: &dyn Speak) -> i32 =
    x.speak()

fn main() -> i32 =
    let r = Rock { n: 1 }
    call_ref(&r)
EOF3
expect_check_fail_msg "$tmpdir/ref_dyn_missing_impl_fail.w" "type 'Rock' does not implement trait 'Speak' required for dyn parameter"

# Negative: non-implementor cannot coerce to Box[dyn Trait].
cat >"$tmpdir/box_dyn_missing_impl_fail.w" <<'EOF4'
trait Speak =
    fn speak(self: Self) -> i32

type Rock = { n: i32 }

fn call_box(x: Box[dyn Speak]) -> i32 =
    x.speak()

fn main() -> i32 =
    let r = Rock { n: 1 }
    call_box(r)
EOF4
expect_check_fail_msg "$tmpdir/box_dyn_missing_impl_fail.w" "type 'Rock' does not implement trait 'Speak' required for dyn parameter"

if [[ "$failures" -ne 0 ]]; then
  echo "phase5 Box[dyn]/&dyn tests: $failures failure(s)"
  exit 1
fi

echo "phase5 Box[dyn]/&dyn tests: PASS"
