#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler/runtime for phase4 std.net scheduler tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_run_pass() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "PASS(std-net-run) $file"
  else
    echo "FAIL(std-net-run) $file"
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
    echo "FAIL(std-net-check-fail) $file"
    failures=$((failures + 1))
  else
    if grep -Fq "$msg" "$stderr_file"; then
      echo "PASS(std-net-check-fail) $file"
    else
      echo "FAIL(std-net-check-msg) $file"
      cat "$stderr_file"
      failures=$((failures + 1))
    fi
  fi
  rm -f "$stderr_file"
}

expect_async_connect_pass() {
  local file="$tmpdir/std_net_async_connect.w"
  local attempts=5
  local stderr_file="$tmpdir/stderr.connect.$$"

  while [[ "$attempts" -gt 0 ]]; do
    local port=$((30000 + RANDOM % 20000))
    cat >"$file" <<EOF1
use std.net

async fn server(port: i32) -> i32:
    let listen_fd = tcp_listen(port)
    let conn = tcp_accept(listen_fd)
    let _ = socket_close(conn)
    let _ = socket_close(listen_fd)

async fn client(port: i32) -> i32:
    let conn = tcp_connect("localhost", port)
    let _ = socket_close(conn)
    if conn >= 0 then 0 else 1

fn main -> i32:
    let s = server($port)
    let c = client($port)
    let cr = c.await
    let sr = s.await
    if cr == 0 and sr == 0 then 0 else 1
EOF1

    if "$WITH_BIN" run "$file" >/dev/null 2>"$stderr_file"; then
      echo "PASS(std-net-async-connect) port=$port"
      rm -f "$stderr_file"
      return
    fi

    attempts=$((attempts - 1))
  done

  echo "FAIL(std-net-async-connect)"
  cat "$stderr_file"
  rm -f "$stderr_file"
  failures=$((failures + 1))
}

expect_run_pass "bootstrap/test/cases/import_std_net.w"
expect_async_connect_pass

cat >"$tmpdir/std_net_udp_bind_ok.w" <<'EOF2'
use std.net

fn main -> i32:
    let fd = udp_bind(0)
    if fd < 0 then return 1
    let _ = socket_close(fd)
    0
EOF2
expect_run_pass "$tmpdir/std_net_udp_bind_ok.w"

cat >"$tmpdir/std_net_listen_type_fail.w" <<'EOF3'
use std.net

fn main -> i32:
    let _ = tcp_listen("8080")
EOF3
expect_check_fail_msg "$tmpdir/std_net_listen_type_fail.w" "wrong type"

cat >"$tmpdir/std_net_connect_arity_fail.w" <<'EOF4'
use std.net

fn main -> i32:
    let _ = tcp_connect("localhost")
EOF4
expect_check_fail_msg "$tmpdir/std_net_connect_arity_fail.w" "expects 2 argument(s)"

cat >"$tmpdir/std_net_accept_type_fail.w" <<'EOF5'
use std.net

fn main -> i32:
    let _ = tcp_accept("bad")
EOF5
expect_check_fail_msg "$tmpdir/std_net_accept_type_fail.w" "wrong type"

if [[ "$failures" -ne 0 ]]; then
  echo "phase4 std.net scheduler tests: $failures failure(s)"
  exit 1
fi

echo "phase4 std.net scheduler tests: PASS"
