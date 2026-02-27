#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler/runtime for phase6 c_import macro+diagnostics tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_check_pass() {
  local file="$1"
  if "$WITH_BIN" check "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "PASS(phase6-cimport-macro-check) $file"
  else
    echo "FAIL(phase6-cimport-macro-check) $file"
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
    echo "FAIL(phase6-cimport-macro-check-fail) $file"
    failures=$((failures + 1))
  else
    if grep -Fq "$msg" "$stderr_file"; then
      echo "PASS(phase6-cimport-macro-check-fail) $file"
    else
      echo "FAIL(phase6-cimport-macro-check-msg) $file"
      cat "$stderr_file"
      failures=$((failures + 1))
    fi
  fi
  rm -f "$stderr_file"
}

# Positive: simple object-like macros are translated into constants.
cat >"$tmpdir/c_import_macro_constants_ok.w" <<'EOF1'
use c_import("#define ANSWER 42\n#define GREETING \"with\"")

fn main -> i32:
    assert(ANSWER == 42)
    assert(GREETING == "with")
EOF1
expect_check_pass "$tmpdir/c_import_macro_constants_ok.w"

# Positive: function-like macros are skipped (best-effort) without failing import.
cat >"$tmpdir/c_import_macro_function_like_ok.w" <<'EOF2'
use c_import("#define ADD(a,b) ((a)+(b))\n#define BASE 7")

fn main -> i32:
    assert(BASE == 7)
EOF2
expect_check_pass "$tmpdir/c_import_macro_function_like_ok.w"

# Non-happy-path: malformed C import reports improved header-snippet diagnostics.
cat >"$tmpdir/c_import_macro_bad_header_fail.w" <<'EOF3'
use c_import("int broken( ;")

fn main -> i32: 0
EOF3
expect_check_fail_msg "$tmpdir/c_import_macro_bad_header_fail.w" "for header snippet"

if [[ "$failures" -ne 0 ]]; then
  echo "phase6 c_import macro+diagnostics tests: $failures failure(s)"
  exit 1
fi

echo "phase6 c_import macro+diagnostics tests: PASS"
