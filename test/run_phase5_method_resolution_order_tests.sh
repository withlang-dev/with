#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler/runtime for phase5 method-resolution-order tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_run_pass() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "PASS(method-resolution-run) $file"
  else
    echo "FAIL(method-resolution-run) $file"
    cat "$tmpdir/stderr.$$"
    failures=$((failures + 1))
  fi
  rm -f "$tmpdir/stderr.$$"
}

# Baseline trait dispatch sample.
expect_run_pass "test/cases/trait_impl.w"

# Trait method appears first, inherent method appears later:
# inherent must still win for method-call resolution.
cat >"$tmpdir/mro_trait_then_inherent_ok.w" <<'EOF1'
trait Score =
    fn value(self: Self) -> bool

type Box = { v: i32 }

impl Score for Box =
    fn value(self: Box) -> bool =
        true

impl Box =
    fn value(self: Box) -> i32 =
        self.v + 2

fn main() -> i32 =
    let b = Box { v: 0 }
    let a = b.value()
    let c = Box.value(b)
    if a == 2 and c == 2 then 0 else 1
EOF1
expect_run_pass "$tmpdir/mro_trait_then_inherent_ok.w"

# Inherent appears first and trait later: inherent must still win.
cat >"$tmpdir/mro_inherent_then_trait_ok.w" <<'EOF2'
trait Measure =
    fn score(self: Self) -> bool

type Item = { v: i32 }

impl Item =
    fn score(self: Item) -> i32 =
        self.v + 7

impl Measure for Item =
    fn score(self: Item) -> bool =
        false

fn main() -> i32 =
    let it = Item { v: 1 }
    let a = it.score()
    let b = Item.score(it)
    if a == 8 and b == 8 then 0 else 1
EOF2
expect_run_pass "$tmpdir/mro_inherent_then_trait_ok.w"

# If there is no inherent method, trait impl method remains callable.
cat >"$tmpdir/mro_trait_only_ok.w" <<'EOF3'
trait Eval =
    fn score(self: Self) -> i32

type Node = { v: i32 }

impl Eval for Node =
    fn score(self: Node) -> i32 =
        self.v + 1

fn main() -> i32 =
    let n = Node { v: 4 }
    if n.score() == 5 then 0 else 1
EOF3
expect_run_pass "$tmpdir/mro_trait_only_ok.w"

if [[ "$failures" -ne 0 ]]; then
  echo "phase5 method-resolution-order tests: $failures failure(s)"
  exit 1
fi

echo "phase5 method-resolution-order tests: PASS"
