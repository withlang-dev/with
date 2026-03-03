#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler binary for phase2 pipeline-ops tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_run_pass() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>/dev/null; then
    echo "PASS(pipeline-ops-run) $file"
  else
    echo "FAIL(pipeline-ops-run) $file"
    failures=$((failures + 1))
  fi
}

expect_check_fail() {
  local file="$1"
  if "$WITH_BIN" check "$file" >/dev/null 2>/dev/null; then
    echo "FAIL(pipeline-ops-fail) $file"
    failures=$((failures + 1))
  else
    echo "PASS(pipeline-ops-fail) $file"
  fi
}

expect_check_fail_msg() {
  local file="$1"
  local msg="$2"
  local stderr_file="$tmpdir/stderr.msg.$$"
  if "$WITH_BIN" check "$file" >/dev/null 2>"$stderr_file"; then
    echo "FAIL(pipeline-ops-fail-msg) $file"
    failures=$((failures + 1))
  else
    if grep -Fq "$msg" "$stderr_file"; then
      echo "PASS(pipeline-ops-fail-msg) $file"
    else
      echo "FAIL(pipeline-ops-fail-msg-text) $file"
      cat "$stderr_file"
      failures=$((failures + 1))
    fi
  fi
  rm -f "$stderr_file"
}

cat >"$tmpdir/pipeline_forward_ok.w" <<'EOF1'
fn inc(x: i32) -> i32: x + 1
fn add(a: i32, b: i32) -> i32: a + b
fn mul(a: i32, b: i32) -> i32: a * b

fn main -> i32:
    let a = 5 |> inc
    let b = 4 |> add(3)
    let c = 3 |> add(2) |> mul(4)
    if a == 6 and b == 7 and c == 20 then 0 else 1
EOF1
expect_run_pass "$tmpdir/pipeline_forward_ok.w"

cat >"$tmpdir/pipeline_backward_apply_ok.w" <<'EOF2'
fn inc(x: i32) -> i32: x + 1

fn main -> i32:
    let out = inc <| 41
    if out == 42 then 0 else 1
EOF2
expect_run_pass "$tmpdir/pipeline_backward_apply_ok.w"

cat >"$tmpdir/pipeline_compose_ok.w" <<'EOF3'
fn double(x: i32) -> i32: x * 2
fn add1(x: i32) -> i32: x + 1

fn main -> i32:
    let f = double >> add1
    let g = add1 << double
    if f(5) == 11 and g(5) == 11 then 0 else 1
EOF3
expect_run_pass "$tmpdir/pipeline_compose_ok.w"

cat >"$tmpdir/pipeline_bad_rhs_fail.w" <<'EOF4'
fn main -> i32:
    let _bad = 1 |> 2
EOF4
expect_check_fail "$tmpdir/pipeline_bad_rhs_fail.w"

cat >"$tmpdir/pipeline_collection_iter_ok.w" <<'EOF5'
fn inc(x: i32) -> i32: x + 1

fn main -> i32:
    let arr = [1, 2, 3]
    let arr2: Vec[i32] = arr |> map(inc)
    let slice = arr[1..3]
    let slice2: Vec[i32] = slice |> map(inc)

    let mut m = HashMap.new[str, i32]()
    m.insert("a", 1)
    m.insert("b", 2)

    let mut s = HashSet.new[i32]()
    s.insert(10)
    s.insert(11)

    let v = vec![4, 5]
    let v2: Vec[i32] = v |> map(inc)

    let c1 = m |> count
    let c2 = s |> count

    if arr2.get(0) == 2 and arr2.get(2) == 4 and slice2.len() == 2 and
       slice2.get(0) == 3 and slice2.get(1) == 4 and
       v2.get(0) == 5 and v2.get(1) == 6 and
       c1 == 2 and c2 == 2 then 0 else 1
EOF5
expect_run_pass "$tmpdir/pipeline_collection_iter_ok.w"

cat >"$tmpdir/pipeline_auto_collect_typed_let_ok.w" <<'EOF6'
fn inc(x: i32) -> i32: x + 1

fn main -> i32:
    let out: Vec[i32] = [1, 2, 3] |> map(inc)
    if out.get(0) == 2 and out.get(2) == 4 then 0 else 1
EOF6
expect_run_pass "$tmpdir/pipeline_auto_collect_typed_let_ok.w"

cat >"$tmpdir/pipeline_auto_collect_call_arg_ok.w" <<'EOF7'
fn inc(x: i32) -> i32: x + 1
fn head(v: Vec[i32]) -> i32:
    v.get(0)

fn main -> i32:
    let v = head([1, 2, 3] |> map(inc))
    if v == 2 then 0 else 1
EOF7
expect_run_pass "$tmpdir/pipeline_auto_collect_call_arg_ok.w"

cat >"$tmpdir/pipeline_auto_collect_return_ok.w" <<'EOF8'
fn inc(x: i32) -> i32: x + 1

fn mk -> Vec[i32]:
    [1, 2, 3] |> map(inc)

fn main -> i32:
    let v = mk()
    if v.get(1) == 3 then 0 else 1
EOF8
expect_run_pass "$tmpdir/pipeline_auto_collect_return_ok.w"

cat >"$tmpdir/pipeline_auto_collect_untyped_let_fail.w" <<'EOF9'
fn inc(x: i32) -> i32: x + 1

fn main -> i32:
    let out = [1, 2, 3] |> map(inc)
    out.len() as i32
EOF9
expect_check_fail_msg "$tmpdir/pipeline_auto_collect_untyped_let_fail.w" "cannot infer destination collection type for pipeline result"

if [[ "$failures" -ne 0 ]]; then
  echo "phase2 pipeline-ops tests: $failures failure(s)"
  exit 1
fi

echo "phase2 pipeline-ops tests: PASS"
