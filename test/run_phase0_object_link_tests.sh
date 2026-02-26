#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler binary for object/link tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_build_and_run_pass() {
  local file="$1"
  local stem
  stem="$(basename "$file" .w)"
  local bin="$tmpdir/$stem"

  if ! "$WITH_BIN" build "$file" >/dev/null 2>/dev/null; then
    echo "FAIL(obj-link-build) $file"
    failures=$((failures + 1))
    return
  fi

  if [[ ! -x "$bin" ]]; then
    echo "FAIL(obj-link-binary-missing) $file"
    failures=$((failures + 1))
    return
  fi

  if "$bin" >/dev/null 2>/dev/null; then
    echo "PASS(obj-link) $file"
  else
    echo "FAIL(obj-link-run) $file"
    failures=$((failures + 1))
  fi
}

expect_build_fail() {
  local file="$1"
  if "$WITH_BIN" build "$file" >/dev/null 2>/dev/null; then
    echo "FAIL(obj-link-negative) $file"
    failures=$((failures + 1))
  else
    echo "PASS(obj-link-negative) $file"
  fi
}

cat >"$tmpdir/object_link_simple.w" <<'EOF1'
fn main() -> i32 =
    if 2 + 2 == 4 then 0 else 1
EOF1
expect_build_and_run_pass "$tmpdir/object_link_simple.w"

cat >"$tmpdir/extadd.c" <<'C1'
int ext_add(int a, int b) { return a + b + 5; }
C1
cc -c "$tmpdir/extadd.c" -o "$tmpdir/extadd.o"
ar rcs "$tmpdir/libextadd.a" "$tmpdir/extadd.o"

cat >"$tmpdir/object_link_cimport_ok.w" <<'EOF2'
use c_import("int ext_add(int, int);", link: "extadd")

fn main() -> i32 =
    if ext_add(1, 2) == 8 then 0 else 1
EOF2
if LIBRARY_PATH="$tmpdir${LIBRARY_PATH:+:$LIBRARY_PATH}" "$WITH_BIN" build "$tmpdir/object_link_cimport_ok.w" >/dev/null 2>/dev/null && "$tmpdir/object_link_cimport_ok" >/dev/null 2>/dev/null; then
  echo "PASS(obj-link-cimport) $tmpdir/object_link_cimport_ok.w"
else
  echo "FAIL(obj-link-cimport) $tmpdir/object_link_cimport_ok.w"
  failures=$((failures + 1))
fi

cat >"$tmpdir/object_link_cimport_missing_link.w" <<'EOF3'
use c_import("int ext_add(int, int);")

fn main() -> i32 =
    if ext_add(1, 2) == 8 then 0 else 1
EOF3
expect_build_fail "$tmpdir/object_link_cimport_missing_link.w"

if [[ "$failures" -ne 0 ]]; then
  echo "phase0 object/link tests: $failures failure(s)"
  exit 1
fi

echo "phase0 object/link tests: PASS"
