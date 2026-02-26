#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler/runtime for phase5 object-safety diagnostics tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_run_pass() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "PASS(object-safety-run) $file"
  else
    echo "FAIL(object-safety-run) $file"
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
    echo "FAIL(object-safety-check-fail) $file"
    failures=$((failures + 1))
  else
    if grep -Fq "$msg" "$stderr_file"; then
      echo "PASS(object-safety-check-fail) $file"
    else
      echo "FAIL(object-safety-check-msg) $file"
      cat "$stderr_file"
      failures=$((failures + 1))
    fi
  fi
  rm -f "$stderr_file"
}

# Positive baseline: object-safe dyn traits remain usable.
expect_run_pass "test/cases/dyn_trait.w"

# Non-object-safe: no self parameter.
cat >"$tmpdir/object_safety_no_self_fail.w" <<'EOF1'
trait Bad =
    fn make() -> i32

fn use_dyn(x: dyn Bad) -> i32 =
    0

fn main() -> i32 = 0
EOF1
expect_check_fail_msg "$tmpdir/object_safety_no_self_fail.w" "is not object-safe: method 'make' has no self parameter"

# Non-object-safe: generic trait method.
cat >"$tmpdir/object_safety_generic_method_fail.w" <<'EOF2'
trait Factory =
    fn make[T](self: Self) -> T

fn use_dyn(x: dyn Factory) -> i32 =
    0

fn main() -> i32 = 0
EOF2
expect_check_fail_msg "$tmpdir/object_safety_generic_method_fail.w" "is not object-safe: method 'make' is generic"

# Non-object-safe: method returning Self.
cat >"$tmpdir/object_safety_returns_self_fail.w" <<'EOF3'
trait CloneLike =
    fn clone(self: Self) -> Self

fn use_dyn(x: dyn CloneLike) -> i32 =
    0

fn main() -> i32 = 0
EOF3
expect_check_fail_msg "$tmpdir/object_safety_returns_self_fail.w" "is not object-safe: method 'clone' returns Self"

if [[ "$failures" -ne 0 ]]; then
  echo "phase5 object-safety diagnostics tests: $failures failure(s)"
  exit 1
fi

echo "phase5 object-safety diagnostics tests: PASS"
