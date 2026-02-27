#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler/runtime for phase6 derive(all) conservative tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_run_pass() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "PASS(phase6-derive-all-run) $file"
  else
    echo "FAIL(phase6-derive-all-run) $file"
    cat "$tmpdir/stderr.$$"
    failures=$((failures + 1))
  fi
  rm -f "$tmpdir/stderr.$$"
}

expect_run_fail() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "FAIL(phase6-derive-all-run-fail) $file"
    failures=$((failures + 1))
  else
    echo "PASS(phase6-derive-all-run-fail) $file"
  fi
  rm -f "$tmpdir/stderr.$$"
}

# Positive: derive(all) on qualifying fields should provide Eq+Clone behavior.
expect_run_pass "bootstrap/test/cases/derive_all.w"

# Positive: derive(all) on non-qualifying fields should still compile when
# dropped traits are not used.
cat >"$tmpdir/derive_all_drop_traits_ok.w" <<'EOF1'
@[derive(all)]
type Bag = { items: Vec[i32] }

fn main -> i32:
    let b = Bag { items: Vec.new() }
    assert(b.items.len() == 0)
EOF1
expect_run_pass "$tmpdir/derive_all_drop_traits_ok.w"

# Non-happy-path: clone should be absent when derive(all) drops Clone.
cat >"$tmpdir/derive_all_clone_dropped_fail.w" <<'EOF2'
@[derive(all)]
type Bag = { items: Vec[i32] }

fn main -> i32:
    let b = Bag { items: Vec.new() }
    let _ = b.clone()
EOF2
expect_run_fail "$tmpdir/derive_all_clone_dropped_fail.w"

# Non-happy-path: Eq overload should be absent when derive(all) drops Eq.
cat >"$tmpdir/derive_all_eq_dropped_fail.w" <<'EOF3'
@[derive(all)]
type Bag = { items: Vec[i32] }

fn main -> i32:
    let a = Bag { items: Vec.new() }
    let b = Bag { items: Vec.new() }
    assert(a == b)
EOF3
expect_run_fail "$tmpdir/derive_all_eq_dropped_fail.w"

if [[ "$failures" -ne 0 ]]; then
  echo "phase6 derive(all) conservative tests: $failures failure(s)"
  exit 1
fi

echo "phase6 derive(all) conservative tests: PASS"
