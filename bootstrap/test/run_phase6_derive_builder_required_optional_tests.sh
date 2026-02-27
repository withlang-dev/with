#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler/runtime for phase6 derive(Builder) required/optional tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_run_pass() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "PASS(phase6-derive-builder-run) $file"
  else
    echo "FAIL(phase6-derive-builder-run) $file"
    cat "$tmpdir/stderr.$$"
    failures=$((failures + 1))
  fi
  rm -f "$tmpdir/stderr.$$"
}

expect_run_fail() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "FAIL(phase6-derive-builder-run-fail) $file"
    failures=$((failures + 1))
  else
    echo "PASS(phase6-derive-builder-run-fail) $file"
  fi
  rm -f "$tmpdir/stderr.$$"
}

# Positive baseline.
expect_run_pass "bootstrap/test/cases/derive_builder_generated.w"

# Positive: defaults are optional, required field must be provided.
cat >"$tmpdir/derive_builder_required_optional_ok.w" <<'EOF1'
@[derive(Builder)]
type Config = {
    host: str,
    port: i32 = 8080,
    tls: bool = false,
}

fn main -> i32:
    let a = Config.builder().host("localhost").build().unwrap()
    assert(a.host == "localhost")
    assert(a.port == 8080)
    assert(not a.tls)

    let b = Config.builder().host("prod").port(443).tls(true).build().unwrap()
    assert(b.port == 443)
    assert(b.tls)
EOF1
expect_run_pass "$tmpdir/derive_builder_required_optional_ok.w"

# Non-happy-path: missing required field should fail at build/unwrap.
cat >"$tmpdir/derive_builder_missing_required_fail.w" <<'EOF2'
@[derive(Builder)]
type Config = {
    host: str,
    port: i32 = 8080,
}

fn main -> i32:
    let _ = Config.builder().build().unwrap()
EOF2
expect_run_fail "$tmpdir/derive_builder_missing_required_fail.w"

# Non-happy-path: builder API should not exist without derive(Builder).
cat >"$tmpdir/derive_builder_without_derive_fail.w" <<'EOF3'
type Plain = { x: i32 }

fn main -> i32:
    let _ = Plain.builder()
EOF3
expect_run_fail "$tmpdir/derive_builder_without_derive_fail.w"

if [[ "$failures" -ne 0 ]]; then
  echo "phase6 derive(Builder) required/optional tests: $failures failure(s)"
  exit 1
fi

echo "phase6 derive(Builder) required/optional tests: PASS"
