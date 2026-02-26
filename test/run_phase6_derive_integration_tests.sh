#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler/runtime for phase6 derive-integration tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_run_pass() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "PASS(phase6-derive-run) $file"
  else
    echo "FAIL(phase6-derive-run) $file"
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
    echo "FAIL(phase6-derive-check-fail) $file"
    failures=$((failures + 1))
  else
    if grep -Fq "$msg" "$stderr_file"; then
      echo "PASS(phase6-derive-check-fail) $file"
    else
      echo "FAIL(phase6-derive-check-msg) $file"
      cat "$stderr_file"
      failures=$((failures + 1))
    fi
  fi
  rm -f "$stderr_file"
}

# Positive: explicit derive integrations.
expect_run_pass "test/cases/derive_eq.w"
expect_run_pass "test/cases/derive_clone.w"
expect_run_pass "test/cases/derive_all.w"
expect_run_pass "test/cases/derive_builder_generated.w"

# Non-happy-path: unknown derive trait must fail in semantic checking.
cat >"$tmpdir/derive_unknown_trait_fail.w" <<'EOF1'
@[derive(Serialize)]
type User = { id: i32 }

fn main() -> i32 = 0
EOF1
expect_check_fail_msg "$tmpdir/derive_unknown_trait_fail.w" "unknown derive trait"

# Non-happy-path: derive(Builder) only allowed on structs.
cat >"$tmpdir/derive_builder_enum_fail.w" <<'EOF2'
@[derive(Builder)]
type Kind = A | B

fn main() -> i32 = 0
EOF2
expect_check_fail_msg "$tmpdir/derive_builder_enum_fail.w" "requires a struct"

# Non-happy-path baseline for explicit derive(Copy) ineligible type.
expect_check_fail_msg "test/gaps/phase6/p6_derive_copy_ineligible.check_fail.w" "cannot derive Copy"

if [[ "$failures" -ne 0 ]]; then
  echo "phase6 derive-integration tests: $failures failure(s)"
  exit 1
fi

echo "phase6 derive-integration tests: PASS"
