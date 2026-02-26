#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler binary for phase2 with-form2 tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_run_pass() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>/dev/null; then
    echo "PASS(with-form2-run) $file"
  else
    echo "FAIL(with-form2-run) $file"
    failures=$((failures + 1))
  fi
}

expect_check_fail() {
  local file="$1"
  if "$WITH_BIN" check "$file" >/dev/null 2>/dev/null; then
    echo "FAIL(with-form2-fail) $file"
    failures=$((failures + 1))
  else
    echo "PASS(with-form2-fail) $file"
  fi
}

cat >"$tmpdir/with_form2_builder_ok.w" <<'EOF1'
type Config = { timeout: i32, retries: i32 }

fn main -> i32:
    let cfg = with Config { timeout: 10, retries: 1 } as mut c:
        c.timeout = 20
        c.retries = 3

    let v = with Config { timeout: 5, retries: 0 } as mut c:
        c.timeout = 9
        c.timeout + 1

    if cfg.timeout == 20 and cfg.retries == 3 and v == 10 then 0 else 1
EOF1
expect_run_pass "$tmpdir/with_form2_builder_ok.w"

cat >"$tmpdir/with_form2_type_mismatch_fail.w" <<'EOF2'
type Config = { timeout: i32, retries: i32 }

fn main -> i32:
    let _cfg = with Config { timeout: 10, retries: 1 } as mut c:
        c.timeout = true
        c
    0
EOF2
expect_check_fail "$tmpdir/with_form2_type_mismatch_fail.w"

if [[ "$failures" -ne 0 ]]; then
  echo "phase2 with-form2 tests: $failures failure(s)"
  exit 1
fi

echo "phase2 with-form2 tests: PASS"
