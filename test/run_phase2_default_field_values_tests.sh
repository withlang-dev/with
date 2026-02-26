#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler binary for phase2 default-field-values tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_run_pass() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>/dev/null; then
    echo "PASS(default-fields-run) $file"
  else
    echo "FAIL(default-fields-run) $file"
    failures=$((failures + 1))
  fi
}

expect_check_fail() {
  local file="$1"
  if "$WITH_BIN" check "$file" >/dev/null 2>/dev/null; then
    echo "FAIL(default-fields-fail) $file"
    failures=$((failures + 1))
  else
    echo "PASS(default-fields-fail) $file"
  fi
}

cat >"$tmpdir/default_fields_insert_ok.w" <<'EOF1'
type Config = { port: i32 = 8080, debug: bool = false, retries: i32 }

fn main() -> i32 =
    let cfg = Config { retries: 3 }
    if cfg.port == 8080 and (not cfg.debug) and cfg.retries == 3 then 0 else 1
EOF1
expect_run_pass "$tmpdir/default_fields_insert_ok.w"

cat >"$tmpdir/default_fields_override_ok.w" <<'EOF2'
type Config = { port: i32 = 8080, debug: bool = false, retries: i32 }

fn main() -> i32 =
    let cfg = Config { port: 9000, retries: 1 }
    if cfg.port == 9000 and (not cfg.debug) and cfg.retries == 1 then 0 else 1
EOF2
expect_run_pass "$tmpdir/default_fields_override_ok.w"

cat >"$tmpdir/default_fields_missing_required_fail.w" <<'EOF3'
type Config = { port: i32 = 8080, debug: bool = false, retries: i32 }

fn main() -> i32 =
    let _cfg = Config { port: 9090 }
    0
EOF3
expect_check_fail "$tmpdir/default_fields_missing_required_fail.w"

if [[ "$failures" -ne 0 ]]; then
  echo "phase2 default-field-values tests: $failures failure(s)"
  exit 1
fi

echo "phase2 default-field-values tests: PASS"
