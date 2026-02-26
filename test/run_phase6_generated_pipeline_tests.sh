#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler/runtime for phase6 generated-checking tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_run_pass() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "PASS(phase6-generated-run) $file"
  else
    echo "FAIL(phase6-generated-run) $file"
    cat "$tmpdir/stderr.$$"
    failures=$((failures + 1))
  fi
  rm -f "$tmpdir/stderr.$$"
}

expect_check_fail_msg() {
  local file="$1"
  local msg="$2"
  local stderr_file="$tmpdir/stderr.err.$$"
  if "$WITH_BIN" check "$file" >/dev/null 2>"$stderr_file"; then
    echo "FAIL(phase6-generated-check-fail) $file"
    failures=$((failures + 1))
  else
    if grep -Fq "$msg" "$stderr_file"; then
      echo "PASS(phase6-generated-check-fail) $file"
    else
      echo "FAIL(phase6-generated-check-msg) $file"
      cat "$stderr_file"
      failures=$((failures + 1))
    fi
  fi
  rm -f "$stderr_file"
}

# Positive: generated derive methods are accepted and executable.
cat >"$tmpdir/generated_pipeline_positive.w" <<'EOF1'
@[derive(Eq, Clone)]
type Pair = { a: i32, b: i32 }

fn main() -> i32 =
    let p = Pair { a: 1, b: 2 }
    let q = p.clone()
    assert(p == q)
    0
EOF1
expect_run_pass "$tmpdir/generated_pipeline_positive.w"

# Non-happy-path: explicit derive(Eq) must be checked against field capabilities.
cat >"$tmpdir/generated_pipeline_eq_fail.w" <<'EOF2'
@[derive(Eq)]
type Bad = { items: Vec[i32] }

fn main() -> i32 = 0
EOF2
expect_check_fail_msg "$tmpdir/generated_pipeline_eq_fail.w" "cannot derive Eq"

# Non-happy-path: explicit derive(Clone) must be checked against field capabilities.
cat >"$tmpdir/generated_pipeline_clone_fail.w" <<'EOF3'
@[derive(Clone)]
type BadFn = { f: fn(i32) -> i32 }

fn id(x: i32) -> i32 = x
fn main() -> i32 =
    let _ = BadFn { f: id }
    0
EOF3
expect_check_fail_msg "$tmpdir/generated_pipeline_clone_fail.w" "cannot derive Clone"

if [[ "$failures" -ne 0 ]]; then
  echo "phase6 generated-checking tests: $failures failure(s)"
  exit 1
fi

echo "phase6 generated-checking tests: PASS"
