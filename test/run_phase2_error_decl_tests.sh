#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler binary for phase2 error-declaration tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_run_pass() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>/dev/null; then
    echo "PASS(error-decl-run) $file"
  else
    echo "FAIL(error-decl-run) $file"
    failures=$((failures + 1))
  fi
}

expect_check_fail() {
  local file="$1"
  if "$WITH_BIN" check "$file" >/dev/null 2>/dev/null; then
    echo "FAIL(error-decl-check-fail) $file"
    failures=$((failures + 1))
  else
    echo "PASS(error-decl-check-fail) $file"
  fi
}

cat >"$tmpdir/error_decl_basic_ok.w" <<'EOF1'
error FileError =
    NotFound
    PermissionDenied

fn code(e: FileError) -> i32 =
    match e
        NotFound -> 1
        PermissionDenied -> 2

fn main() -> i32 =
    let e: FileError = NotFound
    if code(e) == 1 then 0 else 1
EOF1
expect_run_pass "$tmpdir/error_decl_basic_ok.w"

cat >"$tmpdir/error_decl_payload_ok.w" <<'EOF2'
error IoError =
    Disk(str)
    Permission(i32)

fn code(e: IoError) -> i32 =
    match e
        Disk(msg) -> msg.len() as i32
        Permission(v) -> v

fn main() -> i32 =
    let a: IoError = Disk("oops")
    let b: IoError = Permission(7)
    if code(a) == 4 and code(b) == 7 then 0 else 1
EOF2
expect_run_pass "$tmpdir/error_decl_payload_ok.w"

cat >"$tmpdir/error_decl_comma_ok.w" <<'EOF3'
error NetError = Timeout, Closed

fn main() -> i32 =
    let e: NetError = Closed
    let v = match e
        Timeout -> 1
        Closed -> 2
    if v == 2 then 0 else 1
EOF3
expect_run_pass "$tmpdir/error_decl_comma_ok.w"

cat >"$tmpdir/error_decl_bad_payload_syntax_fail.w" <<'EOF4'
error BadError =
    Disk(str

fn main() -> i32 = 0
EOF4
expect_check_fail "$tmpdir/error_decl_bad_payload_syntax_fail.w"

cat >"$tmpdir/error_decl_unknown_variant_fail.w" <<'EOF5'
error MyError = A, B

fn main() -> i32 =
    let e: MyError = C
    match e
        A -> 0
        B -> 1
EOF5
expect_check_fail "$tmpdir/error_decl_unknown_variant_fail.w"

if [[ "$failures" -ne 0 ]]; then
  echo "phase2 error-declaration tests: $failures failure(s)"
  exit 1
fi

echo "phase2 error-declaration tests: PASS"
