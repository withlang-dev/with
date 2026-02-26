#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler/runtime for phase5 orphan/coherence tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_run_pass() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "PASS(orphan-coherence-run) $file"
  else
    echo "FAIL(orphan-coherence-run) $file"
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
    echo "FAIL(orphan-coherence-check-fail) $file"
    failures=$((failures + 1))
  else
    if grep -Fq "$msg" "$stderr_file"; then
      echo "PASS(orphan-coherence-check-fail) $file"
    else
      echo "FAIL(orphan-coherence-check-msg) $file"
      cat "$stderr_file"
      failures=$((failures + 1))
    fi
  fi
  rm -f "$stderr_file"
}

expect_run_pass "test/cases/trait_conform.w"

cat >"$tmpdir/coherence_local_trait_for_primitive_ok.w" <<'EOF1'
trait ShowInt =
    fn show(self: Self) -> i32

impl ShowInt for i32 =
    fn show(self: i32) -> i32:
        self

fn main -> i32: 0
EOF1
expect_run_pass "$tmpdir/coherence_local_trait_for_primitive_ok.w"

cat >"$tmpdir/external_trait.w" <<'EOF2'
trait ExternalTrait =
    fn value(self: Self) -> i32
EOF2

cat >"$tmpdir/orphan_local_type_with_external_trait_ok.w" <<'EOF3'
use external_trait

type LocalBox = { v: i32 }

impl ExternalTrait for LocalBox =
    fn value(self: LocalBox) -> i32:
        self.v

fn main -> i32: 0
EOF3
expect_run_pass "$tmpdir/orphan_local_type_with_external_trait_ok.w"

cat >"$tmpdir/external_defs.w" <<'EOF4'
trait ExternalValue =
    fn value(self: Self) -> i32

type ExternalBox = { v: i32 }
EOF4

cat >"$tmpdir/orphan_foreign_trait_foreign_type_fail.w" <<'EOF5'
use external_defs

impl ExternalValue for ExternalBox =
    fn value(self: ExternalBox) -> i32:
        self.v

fn main -> i32: 0
EOF5
expect_check_fail_msg "$tmpdir/orphan_foreign_trait_foreign_type_fail.w" "orphan rule violation: impl requires a local trait or local type"

cat >"$tmpdir/coherence_duplicate_impl_fail.w" <<'EOF2'
trait Value =
    fn value(self: Self) -> i32

type Box = { v: i32 }

impl Value for Box =
    fn value(self: Box) -> i32:
        self.v

impl Value for Box =
    fn value(self: Box) -> i32:
        self.v + 1

fn main -> i32: 0
EOF2
expect_check_fail_msg "$tmpdir/coherence_duplicate_impl_fail.w" "duplicate implementation of trait 'Value' for type 'Box'"

cat >"$tmpdir/orphan_unknown_trait_fail.w" <<'EOF6'
type Box = { v: i32 }

impl UnknownTrait for Box =
    fn value(self: Box) -> i32:
        self.v

fn main -> i32: 0
EOF6
expect_check_fail_msg "$tmpdir/orphan_unknown_trait_fail.w" "unknown trait"

cat >"$tmpdir/orphan_unknown_type_fail.w" <<'EOF7'
trait KnownTrait =
    fn value(self: Self) -> i32

impl KnownTrait for MissingType =
    fn value(self: MissingType) -> i32:
        0

fn main -> i32: 0
EOF7
expect_check_fail_msg "$tmpdir/orphan_unknown_type_fail.w" "unknown type"

if [[ "$failures" -ne 0 ]]; then
  echo "phase5 orphan/coherence tests: $failures failure(s)"
  exit 1
fi

echo "phase5 orphan/coherence tests: PASS"
