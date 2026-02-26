#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler binary for alias tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_check_pass() {
  local file="$1"
  if "$WITH_BIN" check "$file" >/dev/null 2>/dev/null; then
    echo "PASS(alias-pass) $file"
  else
    echo "FAIL(alias-pass) $file"
    failures=$((failures + 1))
  fi
}

expect_check_fail() {
  local file="$1"
  if "$WITH_BIN" check "$file" >/dev/null 2>/dev/null; then
    echo "FAIL(alias-negative) $file"
    failures=$((failures + 1))
  else
    echo "PASS(alias-negative) $file"
  fi
}

cat >"$tmpdir/alias_ok.w" <<'EOF'
fn takes_view(v: StrView) -> bool:
    true

fn takes_str(v: &str) -> bool:
    true

fn main -> bool:
    let s: String = "abc"
    let v: StrView = &s
    let w: &str = &s
    takes_view(v) and takes_str(w)
EOF
expect_check_pass "$tmpdir/alias_ok.w"

cat >"$tmpdir/alias_unknown.w" <<'EOF'
fn main -> i32:
    let s: StrVeiw = "abc"
EOF
expect_check_fail "$tmpdir/alias_unknown.w"

if [[ "$failures" -ne 0 ]]; then
  echo "phase0 alias tests: $failures failure(s)"
  exit 1
fi

echo "phase0 alias tests: PASS"
