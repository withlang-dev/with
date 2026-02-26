#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler binary for phase2 enum-variant-shorthand tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_run_pass() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>/dev/null; then
    echo "PASS(enum-shorthand-run) $file"
  else
    echo "FAIL(enum-shorthand-run) $file"
    failures=$((failures + 1))
  fi
}

expect_check_fail_msg() {
  local file="$1"
  local msg="$2"
  local out
  if out="$("$WITH_BIN" check "$file" 2>&1 >/dev/null)"; then
    echo "FAIL(enum-shorthand-fail) $file"
    failures=$((failures + 1))
    return
  fi
  if grep -Fq "$msg" <<<"$out"; then
    echo "PASS(enum-shorthand-fail) $file"
  else
    echo "FAIL(enum-shorthand-msg) $file"
    failures=$((failures + 1))
  fi
}

cat >"$tmpdir/enum_shorthand_context_ok.w" <<'EOF1'
type A = Same | OnlyA
type B = Same | OnlyB
type Holder = { a: A, b: B }

fn default_a() -> A = .Same
fn default_b() -> B = .Same

fn score_a(v: A) -> i32 =
    match v
        .Same -> 1
        .OnlyA -> 2

fn main() -> i32 =
    let a: A = .Same
    let b: B = .Same
    let h = Holder { a: .Same, b: .Same }
    let call_score = score_a(.Same)
    let ok =
        score_a(a) == 1 and default_a() == a and default_b() == b and
        h.a == a and h.b == b and call_score == 1
    if ok then 0 else 1
EOF1
expect_run_pass "$tmpdir/enum_shorthand_context_ok.w"

cat >"$tmpdir/enum_shorthand_wrong_expected_fail.w" <<'EOF2'
type A = Same | OnlyA
type B = Same | OnlyB

fn score_a(v: A) -> i32 =
    match v
        Same -> 1
        _ -> 0

fn main() -> i32 =
    let _bad_a: A = .OnlyB
    let _bad_call = score_a(.OnlyB)
    0
EOF2
expect_check_fail_msg "$tmpdir/enum_shorthand_wrong_expected_fail.w" "enum variant shorthand does not match expected enum type"

if [[ "$failures" -ne 0 ]]; then
  echo "phase2 enum-variant-shorthand tests: $failures failure(s)"
  exit 1
fi

echo "phase2 enum-variant-shorthand tests: PASS"
