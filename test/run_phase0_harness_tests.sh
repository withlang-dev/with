#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler binary for harness tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_pass() {
  local file="$1"
  if "$WITH_BIN" test "$file" >/dev/null 2>/dev/null; then
    echo "PASS(harness-pass) $file"
  else
    echo "FAIL(harness-pass) $file"
    failures=$((failures + 1))
  fi
}

expect_fail() {
  local file="$1"
  if "$WITH_BIN" test "$file" >/dev/null 2>/dev/null; then
    echo "FAIL(harness-fail) $file"
    failures=$((failures + 1))
  else
    echo "PASS(harness-fail) $file"
  fi
}

cat >"$tmpdir/default_exit.w" <<'EOF'
fn main() -> i32 =
    0
EOF
expect_pass "$tmpdir/default_exit.w"

cat >"$tmpdir/exit_42.w" <<'EOF'
fn main() -> i32 =
    42
EOF
cat >"$tmpdir/exit_42.exit" <<'EOF'
42
EOF
expect_pass "$tmpdir/exit_42.w"

cat >"$tmpdir/stdout_ok.w" <<'EOF'
fn main() -> i32 =
    println("phase0-harness")
    0
EOF
cat >"$tmpdir/stdout_ok.stdout" <<'EOF'
phase0-harness
EOF
expect_pass "$tmpdir/stdout_ok.w"

cat >"$tmpdir/stdout_mismatch.w" <<'EOF'
fn main() -> i32 =
    println("actual")
    0
EOF
cat >"$tmpdir/stdout_mismatch.stdout" <<'EOF'
expected
EOF
expect_fail "$tmpdir/stdout_mismatch.w"

cat >"$tmpdir/exit_mismatch.w" <<'EOF'
fn main() -> i32 =
    7
EOF
cat >"$tmpdir/exit_mismatch.exit" <<'EOF'
0
EOF
expect_fail "$tmpdir/exit_mismatch.w"

if [[ "$failures" -ne 0 ]]; then
  echo "phase0 harness tests: $failures failure(s)"
  exit 1
fi

echo "phase0 harness tests: PASS"
