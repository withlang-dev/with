#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler binary for phase2 enum-accessors tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_run_pass() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>/dev/null; then
    echo "PASS(enum-accessors-run) $file"
  else
    echo "FAIL(enum-accessors-run) $file"
    failures=$((failures + 1))
  fi
}

expect_build_fail() {
  local file="$1"
  if "$WITH_BIN" build "$file" >/dev/null 2>/dev/null; then
    echo "FAIL(enum-accessors-fail) $file"
    failures=$((failures + 1))
  else
    echo "PASS(enum-accessors-fail) $file"
  fi
}

cat >"$tmpdir/enum_accessors_all_ok.w" <<'EOF1'
type Value = Num(i32) | Text(str) | Nil

fn main -> i32:
    let n = Num(10)
    assert(n.is_Num())
    assert(not n.is_Text())
    assert(not n.is_Nil())

    let n_by_val = n.as_Num()
    assert(n_by_val.is_some())
    assert(n_by_val.unwrap() == 10)

    let n_by_ref = n.as_Num_ref()
    let n_by_mut = n.as_Num_mut()
    assert(n_by_ref.is_some())
    assert(n_by_mut.is_some())

    let t = Text("hello")
    assert(t.as_Num().is_none())
    assert(t.as_Num_ref().is_none())
    assert(t.as_Num_mut().is_none())

    let u: Value = Nil
    assert(u.is_Nil())
EOF1
expect_run_pass "$tmpdir/enum_accessors_all_ok.w"

cat >"$tmpdir/enum_accessors_unit_as_fail.w" <<'EOF2'
type Value = Num(i32) | Text(str) | Nil

fn main -> i32:
    let v: Value = Nil
    let _bad = v.as_Nil()
EOF2
expect_build_fail "$tmpdir/enum_accessors_unit_as_fail.w"

if [[ "$failures" -ne 0 ]]; then
  echo "phase2 enum-accessors tests: $failures failure(s)"
  exit 1
fi

echo "phase2 enum-accessors tests: PASS"
