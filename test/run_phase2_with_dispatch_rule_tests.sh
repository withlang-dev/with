#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler binary for phase2 with-dispatch-rule tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_run_pass() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>/dev/null; then
    echo "PASS(with-dispatch-run) $file"
  else
    echo "FAIL(with-dispatch-run) $file"
    failures=$((failures + 1))
  fi
}

cat >"$tmpdir/with_dispatch_rule_ok.w" <<'EOF1'
type Guard = { v: i32 }
fn Guard.enter(self: Guard) -> i32 = self.v + 10
fn Guard.enter_mut(self: Guard) -> i32 = self.v + 20

type BuilderOnly = { v: i32 }

fn main() -> i32 =
    let a = with Guard { v: 1 } as x:
        x

    let b = with Guard { v: 2 } as mut x:
        x + 1

    let c = with BuilderOnly { v: 3 } as mut x:
        x.v = 9

    // enter() for non-mut => 11
    // enter_mut() for mut => 22 then +1 => 23
    // no enter_mut on BuilderOnly => builder fallback returns updated struct
    if a == 11 and b == 23 and c.v == 9 then 0 else 1
EOF1
expect_run_pass "$tmpdir/with_dispatch_rule_ok.w"

cat >"$tmpdir/with_dispatch_mut_prefers_builder_when_no_enter_mut.w" <<'EOF2'
type HasEnterOnly = { v: i32 }
fn HasEnterOnly.enter(self: HasEnterOnly) -> i32 = self.v

fn main() -> i32 =
    let out = with HasEnterOnly { v: 5 } as mut x:
        x.v = 8
    if out.v == 8 then 0 else 1
EOF2
expect_run_pass "$tmpdir/with_dispatch_mut_prefers_builder_when_no_enter_mut.w"

cat >"$tmpdir/with_dispatch_nonmut_prefers_binding_when_no_enter.w" <<'EOF3'
type HasEnterMutOnly = { v: i32 }
fn HasEnterMutOnly.enter_mut(self: HasEnterMutOnly) -> i32 = self.v

fn main() -> i32 =
    let out = with HasEnterMutOnly { v: 4 } as x:
        x.v + 1
    if out == 5 then 0 else 1
EOF3
expect_run_pass "$tmpdir/with_dispatch_nonmut_prefers_binding_when_no_enter.w"

if [[ "$failures" -ne 0 ]]; then
  echo "phase2 with-dispatch-rule tests: $failures failure(s)"
  exit 1
fi

echo "phase2 with-dispatch-rule tests: PASS"
