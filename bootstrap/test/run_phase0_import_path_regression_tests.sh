#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler binary for import-path regression tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_check_pass() {
  local file="$1"
  if "$WITH_BIN" check "$file" >/dev/null 2>/dev/null; then
    echo "PASS(import-path-regression-pass) $file"
  else
    echo "FAIL(import-path-regression-pass) $file"
    failures=$((failures + 1))
  fi
}

expect_check_fail() {
  local file="$1"
  if "$WITH_BIN" check "$file" >/dev/null 2>/dev/null; then
    echo "FAIL(import-path-regression-negative) $file"
    failures=$((failures + 1))
  else
    echo "PASS(import-path-regression-negative) $file"
  fi
}

# Case 1: nested relative import from imported module.
mkdir -p "$tmpdir/relative/dir"
cat >"$tmpdir/relative/root.w" <<'EOF'
use dir.a

fn main -> i32:
    a()
EOF
cat >"$tmpdir/relative/dir/a.w" <<'EOF'
use b

fn a -> i32:
    b()
EOF
cat >"$tmpdir/relative/dir/b.w" <<'EOF'
fn b -> i32:
    2
EOF
expect_check_pass "$tmpdir/relative/root.w"

# Case 2: nested package-qualified import from imported module.
mkdir -p "$tmpdir/qualified/pkg"
cat >"$tmpdir/qualified/root.w" <<'EOF'
use pkg.a

fn main -> i32:
    a()
EOF
cat >"$tmpdir/qualified/pkg/a.w" <<'EOF'
use pkg.b

fn a -> i32:
    b()
EOF
cat >"$tmpdir/qualified/pkg/b.w" <<'EOF'
fn b -> i32:
    7
EOF
expect_check_pass "$tmpdir/qualified/root.w"

# Case 3: qualified cycle should resolve and terminate.
mkdir -p "$tmpdir/cycle/cycle"
cat >"$tmpdir/cycle/root.w" <<'EOF'
use cycle.a

fn main -> i32:
    a()
EOF
cat >"$tmpdir/cycle/cycle/a.w" <<'EOF'
use cycle.b

fn a -> i32:
    b()
EOF
cat >"$tmpdir/cycle/cycle/b.w" <<'EOF'
use cycle.a

fn b -> i32:
    1
EOF
expect_check_pass "$tmpdir/cycle/root.w"

# Negative sanity check: unresolved qualified target still fails.
mkdir -p "$tmpdir/missing/pkg"
cat >"$tmpdir/missing/root.w" <<'EOF'
use pkg.missing

fn main -> i32:
    0
EOF
expect_check_fail "$tmpdir/missing/root.w"

if [[ "$failures" -ne 0 ]]; then
  echo "phase0 import-path regression tests: $failures failure(s)"
  exit 1
fi

echo "phase0 import-path regression tests: PASS"
