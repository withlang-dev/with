#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler binary for c_import tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_run_pass() {
  local file="$1"
  if "$WITH_BIN" run "$file" >/dev/null 2>/dev/null; then
    echo "PASS(c_import-run) $file"
  else
    echo "FAIL(c_import-run) $file"
    failures=$((failures + 1))
  fi
}

expect_check_fail() {
  local file="$1"
  if "$WITH_BIN" check "$file" >/dev/null 2>/dev/null; then
    echo "FAIL(c_import-negative) $file"
    failures=$((failures + 1))
  else
    echo "PASS(c_import-negative) $file"
  fi
}

cat >"$tmpdir/c_import_stdio.w" <<'EOF'
use c_import("#include <stdio.h>")

fn main() -> i32 =
    puts(c"hello from c_import")
    0
EOF
expect_run_pass "$tmpdir/c_import_stdio.w"

cat >"$tmpdir/c_import_printf.w" <<'EOF'
use c_import("#include <stdio.h>")

fn main() -> i32 =
    printf(c"%s %d\n", c"num", 7)
    0
EOF
expect_run_pass "$tmpdir/c_import_printf.w"

cat >"$tmpdir/c_import_string.w" <<'EOF'
use c_import("#include <string.h>")

fn main() -> i32 =
    let n = strlen(c"abc")
    if n == 3 then 0 else 1
EOF
expect_run_pass "$tmpdir/c_import_string.w"

cat >"$tmpdir/c_import_stdlib.w" <<'EOF'
use c_import("#include <stdlib.h>")

fn main() -> i32 =
    let p = malloc(8)
    if p.as_option().is_none() then return 1
    free(p)
    0
EOF
expect_run_pass "$tmpdir/c_import_stdlib.w"

cat >"$tmpdir/ffi_mod.w" <<'EOF'
use c_import("#include <stdio.h>")

fn call_puts() -> i32 =
    puts(c"injected import")
EOF

cat >"$tmpdir/c_import_injected_module.w" <<'EOF'
use ffi_mod

fn main() -> i32 =
    call_puts()
    0
EOF
expect_run_pass "$tmpdir/c_import_injected_module.w"

cat >"$tmpdir/c_import_missing_header.w" <<'EOF'
use c_import("#include <this_header_should_not_exist_12345.h>")

fn main() -> i32 =
    0
EOF
expect_check_fail "$tmpdir/c_import_missing_header.w"

cat >"$tmpdir/c_import_bad_syntax.w" <<'EOF'
use c_import(123)

fn main() -> i32 =
    0
EOF
expect_check_fail "$tmpdir/c_import_bad_syntax.w"

if [[ "$failures" -ne 0 ]]; then
  echo "phase0 c_import tests: $failures failure(s)"
  exit 1
fi

echo "phase0 c_import tests: PASS"
