#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler/runtime for phase4 send/sync/scopedsend tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_run_pass() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "PASS(send-sync-run) $file"
  else
    echo "FAIL(send-sync-run) $file"
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
    echo "FAIL(send-sync-check-fail) $file"
    failures=$((failures + 1))
  else
    if grep -Fq "$msg" "$stderr_file"; then
      echo "PASS(send-sync-check-fail) $file"
    else
      echo "FAIL(send-sync-check-msg) $file"
      cat "$stderr_file"
      failures=$((failures + 1))
    fi
  fi
  rm -f "$stderr_file"
}

cat >"$tmpdir/channel_send_owned_ok.w" <<'EOF1'
fn main() -> i32 =
    let ch = Channel(2)
    send(ch, 123)
    let v = recv(ch)
    if v == 123 then 0 else 1
EOF1
expect_run_pass "$tmpdir/channel_send_owned_ok.w"

cat >"$tmpdir/channel_send_ephemeral_fail.w" <<'EOF2'
fn main() -> i32 =
    let ch = Channel(2)
    let x = 7
    send(ch, &x)
    0
EOF2
expect_check_fail_msg "$tmpdir/channel_send_ephemeral_fail.w" "channel send requires Send value"

cat >"$tmpdir/spawn_os_owned_capture_ok.w" <<'EOF3'
use std.thread

fn main() -> i32 =
    let base = 5
    let h = spawn_os(|| base + 1)
    let v = join(h)
    if v == 6 then 0 else 1
EOF3
expect_run_pass "$tmpdir/spawn_os_owned_capture_ok.w"

cat >"$tmpdir/spawn_os_ephemeral_capture_fail.w" <<'EOF4'
use std.thread

fn main() -> i32 =
    let x = 41
    let r = &x
    let h = spawn_os(|| *r)
    let _ = join(h)
    0
EOF4
expect_check_fail_msg "$tmpdir/spawn_os_ephemeral_capture_fail.w" "spawn_os requires Send captures"

cat >"$tmpdir/async_scope_scopedsend_ephemeral_ok.w" <<'EOF5'
fn main() -> i32 =
    let n = 9
    let r = &n
    let out = async scope |s|:
        let t = s.track(async: *r)
        t.await
    if out == 9 then 0 else 1
EOF5
expect_run_pass "$tmpdir/async_scope_scopedsend_ephemeral_ok.w"

if [[ "$failures" -ne 0 ]]; then
  echo "phase4 send/sync/scopedsend tests: $failures failure(s)"
  exit 1
fi

echo "phase4 send/sync/scopedsend tests: PASS"
