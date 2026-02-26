#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler binary for phase2 optional-chaining tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_run_pass() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>/dev/null; then
    echo "PASS(optional-chain-run) $file"
  else
    echo "FAIL(optional-chain-run) $file"
    failures=$((failures + 1))
  fi
}

expect_check_fail() {
  local file="$1"
  if "$WITH_BIN" check "$file" >/dev/null 2>/dev/null; then
    echo "FAIL(optional-chain-fail) $file"
    failures=$((failures + 1))
  else
    echo "PASS(optional-chain-fail) $file"
  fi
}

expect_run_fail() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>/dev/null; then
    echo "FAIL(optional-chain-run-fail) $file"
    failures=$((failures + 1))
  else
    echo "PASS(optional-chain-run-fail) $file"
  fi
}

cat >"$tmpdir/optional_chain_option_field_ok.w" <<'EOF1'
type Address = { city: ?str, zip: str }
type Profile = { address: ?Address }

fn main() -> i32 =
    let p1 = Profile { address: Some(Address { city: Some("NYC"), zip: "10001" }) }
    let p2 = Profile { address: None }
    let zip1 = p1.address?.zip ?? "none"
    let zip2 = p2.address?.zip ?? "none"
    if zip1 == "10001" and zip2 == "none" then 0 else 1
EOF1
expect_run_pass "$tmpdir/optional_chain_option_field_ok.w"

cat >"$tmpdir/optional_chain_flatten_ok.w" <<'EOF2'
type Address = { city: ?str }
type Profile = { address: ?Address }

fn main() -> i32 =
    let p = Profile { address: Some(Address { city: Some("NYC") }) }
    let city = p.address?.city
    let len = city?.len() ?? 0
    if len == 3 then 0 else 1
EOF2
expect_run_pass "$tmpdir/optional_chain_flatten_ok.w"

cat >"$tmpdir/optional_chain_method_ok.w" <<'EOF3'
fn main() -> i32 =
    let s1: ?str = Some("hello")
    let s2: ?str = None
    let n1 = s1?.len() ?? 0
    let n2 = s2?.len() ?? 0
    if n1 == 5 and n2 == 0 then 0 else 1
EOF3
expect_run_pass "$tmpdir/optional_chain_method_ok.w"

cat >"$tmpdir/optional_chain_result_ok.w" <<'EOF4'
fn make(flag: bool) -> Result[(i32, i32), i32] =
    if flag then Ok((3, 4)) else Err(9)

fn main() -> i32 =
    let a = make(true)?.0 ?? 0
    let b = make(false)?.0 ?? 0
    if a == 3 and b == 0 then 0 else 1
EOF4
expect_run_pass "$tmpdir/optional_chain_result_ok.w"

cat >"$tmpdir/optional_chain_non_optional_fail.w" <<'EOF5'
fn main() -> i32 =
    let x = 5
    let y = x?.len()
    y ?? 0
EOF5
expect_check_fail "$tmpdir/optional_chain_non_optional_fail.w"

cat >"$tmpdir/optional_chain_bad_field_fail.w" <<'EOF6'
type Point = { x: i32, y: i32 }

fn main() -> i32 =
    let p: ?Point = Some(Point { x: 1, y: 2 })
    let _v = p?.z ?? 0
    0
EOF6
expect_run_fail "$tmpdir/optional_chain_bad_field_fail.w"

cat >"$tmpdir/optional_chain_bad_method_fail.w" <<'EOF7'
fn main() -> i32 =
    let s: ?str = Some("hi")
    let _v = s?.missing_method() ?? 0
    0
EOF7
expect_run_fail "$tmpdir/optional_chain_bad_method_fail.w"

if [[ "$failures" -ne 0 ]]; then
  echo "phase2 optional-chaining tests: $failures failure(s)"
  exit 1
fi

echo "phase2 optional-chaining tests: PASS"
