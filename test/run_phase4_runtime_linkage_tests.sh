#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler/runtime for phase4 runtime-linkage tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_cmd_pass() {
  local label="$1"
  local cmd="$2"
  if bash -lc "$cmd" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "PASS(${label})"
  else
    echo "FAIL(${label})"
    cat "$tmpdir/stderr.$$"
    failures=$((failures + 1))
  fi
  rm -f "$tmpdir/stderr.$$"
}

cat >"$tmpdir/sync_main.w" <<'EOF1'
fn main() -> i32 =
    0
EOF1

cat >"$tmpdir/async_main.w" <<'EOF2'
async fn one() -> i32 =
    1

fn main() -> i32 =
    let t = one()
    let r = t.await
    if r == 1 then 0 else 1
EOF2

expect_cmd_pass "build-sync" "$WITH_BIN build $tmpdir/sync_main.w"
expect_cmd_pass "build-async" "$WITH_BIN build $tmpdir/async_main.w"
expect_cmd_pass "run-sync-bin" "$tmpdir/sync_main"
expect_cmd_pass "run-async-bin" "$tmpdir/async_main"

# Async binary should link fiber runtime symbols.
expect_cmd_pass "async-has-fiber-symbol" "nm $tmpdir/async_main | rg -q \"_with_fiber_spawn|with_fiber_spawn\""

# Sync binary should not require async runtime symbols.
if nm "$tmpdir/sync_main" | rg -q "_with_fiber_spawn|with_fiber_spawn"; then
  echo "FAIL(sync-no-fiber-symbol)"
  failures=$((failures + 1))
else
  echo "PASS(sync-no-fiber-symbol)"
fi

if [[ "$failures" -ne 0 ]]; then
  echo "phase4 runtime linkage tests: $failures failure(s)"
  exit 1
fi

echo "phase4 runtime linkage tests: PASS"
