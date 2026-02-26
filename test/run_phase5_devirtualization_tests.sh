#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler/runtime for phase5 devirtualization tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_run_pass() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "PASS(devirt-run) $file"
  else
    echo "FAIL(devirt-run) $file"
    cat "$tmpdir/stderr.$$"
    failures=$((failures + 1))
  fi
  rm -f "$tmpdir/stderr.$$"
}

expect_ir_contains() {
  local ir_file="$1"
  local needle="$2"
  if rg -Fq "$needle" "$ir_file"; then
    echo "PASS(devirt-ir-has) $needle"
  else
    echo "FAIL(devirt-ir-has) $needle"
    failures=$((failures + 1))
  fi
}

expect_ir_not_contains() {
  local ir_file="$1"
  local needle="$2"
  if rg -Fq "$needle" "$ir_file"; then
    echo "FAIL(devirt-ir-not) $needle"
    failures=$((failures + 1))
  else
    echo "PASS(devirt-ir-not) $needle"
  fi
}

# Known concrete dyn local: should devirtualize direct method call.
cat >"$tmpdir/devirt_known_local.w" <<'EOF1'
trait Speak =
    fn speak(self: Self) -> i32

type Dog = { n: i32 }

impl Speak for Dog =
    fn speak(self: Dog) -> i32 = self.n

fn main() -> i32 =
    let d = Dog { n: 5 }
    let x: Box[dyn Speak] = d
    assert(x.speak() == 5)
    0
EOF1
expect_run_pass "$tmpdir/devirt_known_local.w"
"$WITH_BIN" ir "$tmpdir/devirt_known_local.w" >"$tmpdir/devirt_known_local.ir" 2>"$tmpdir/ir.stderr.$$" || true
expect_ir_contains "$tmpdir/devirt_known_local.ir" "devirt.call"
expect_ir_not_contains "$tmpdir/devirt_known_local.ir" "vtable.gep"
expect_ir_not_contains "$tmpdir/devirt_known_local.ir" "dyncall"
rm -f "$tmpdir/ir.stderr.$$"

# Unknown concrete inside callee param: should retain dynamic dispatch path.
cat >"$tmpdir/devirt_unknown_param.w" <<'EOF2'
trait Speak =
    fn speak(self: Self) -> i32

type Dog = { n: i32 }

impl Speak for Dog =
    fn speak(self: Dog) -> i32 = self.n

fn call(x: Box[dyn Speak]) -> i32 =
    x.speak()

fn main() -> i32 =
    let d = Dog { n: 5 }
    assert(call(d) == 5)
    0
EOF2
expect_run_pass "$tmpdir/devirt_unknown_param.w"
"$WITH_BIN" ir "$tmpdir/devirt_unknown_param.w" >"$tmpdir/devirt_unknown_param.ir" 2>"$tmpdir/ir.stderr.$$" || true
expect_ir_contains "$tmpdir/devirt_unknown_param.ir" "vtable.gep"
expect_ir_contains "$tmpdir/devirt_unknown_param.ir" "dyncall"
rm -f "$tmpdir/ir.stderr.$$"

if [[ "$failures" -ne 0 ]]; then
  echo "phase5 devirtualization tests: $failures failure(s)"
  exit 1
fi

echo "phase5 devirtualization tests: PASS"
