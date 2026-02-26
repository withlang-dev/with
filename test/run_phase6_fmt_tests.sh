#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler/runtime for phase6 fmt tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_fmt_contains() {
  local file="$1"
  local pattern="$2"
  local out_file="$tmpdir/fmt.out.$$"
  if "$WITH_BIN" fmt "$file" >"$out_file" 2>"$tmpdir/stderr.$$"; then
    if grep -Fq "$pattern" "$out_file"; then
      echo "PASS(phase6-fmt-contains) $file :: $pattern"
    else
      echo "FAIL(phase6-fmt-contains) $file :: $pattern"
      cat "$out_file"
      failures=$((failures + 1))
    fi
  else
    echo "FAIL(phase6-fmt-run) $file"
    cat "$tmpdir/stderr.$$"
    failures=$((failures + 1))
  fi
  rm -f "$out_file" "$tmpdir/stderr.$$"
}

expect_fmt_equal() {
  local file="$1"
  local expected="$2"
  local out_file="$tmpdir/fmt.out.$$"
  if "$WITH_BIN" fmt "$file" >"$out_file" 2>"$tmpdir/stderr.$$"; then
    if diff -u <(printf "%s" "$expected") "$out_file" >/dev/null; then
      echo "PASS(phase6-fmt-equal) $file"
    else
      echo "FAIL(phase6-fmt-equal) $file"
      diff -u <(printf "%s" "$expected") "$out_file" || true
      failures=$((failures + 1))
    fi
  else
    echo "FAIL(phase6-fmt-run) $file"
    cat "$tmpdir/stderr.$$"
    failures=$((failures + 1))
  fi
  rm -f "$out_file" "$tmpdir/stderr.$$"
}

expect_fmt_fail_msg() {
  local msg="$1"
  local stderr_file="$tmpdir/fmt.err.$$"
  if "$WITH_BIN" fmt >/dev/null 2>"$stderr_file"; then
    echo "FAIL(phase6-fmt-fail)"
    failures=$((failures + 1))
  else
    if grep -Fq "$msg" "$stderr_file"; then
      echo "PASS(phase6-fmt-fail)"
    else
      echo "FAIL(phase6-fmt-fail-msg)"
      cat "$stderr_file"
      failures=$((failures + 1))
    fi
  fi
  rm -f "$stderr_file"
}

expect_fmt_parse_fail() {
  local file="$1"
  if "$WITH_BIN" fmt "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "FAIL(phase6-fmt-parse-fail) $file"
    failures=$((failures + 1))
  else
    echo "PASS(phase6-fmt-parse-fail) $file"
  fi
  rm -f "$tmpdir/stderr.$$"
}

# Positive: canonical formatting for comment-free source.
cat >"$tmpdir/fmt_canonical_ok.w" <<'EOF1'
fn   main()->i32=1+2
EOF1
expect_fmt_contains "$tmpdir/fmt_canonical_ok.w" "fn main() -> i32 ="
expect_fmt_contains "$tmpdir/fmt_canonical_ok.w" "(1 + 2)"

# Positive: comment preservation path keeps comment-bearing input intact.
cat >"$tmpdir/fmt_comment_preserve_ok.w" <<'EOF2'
// top comment
fn main() -> i32 =
    // inner comment
    0
EOF2
expected_comment_preserved=$'// top comment\nfn main() -> i32 =\n    // inner comment\n    0\n'
expect_fmt_equal "$tmpdir/fmt_comment_preserve_ok.w" "$expected_comment_preserved"

# Non-happy-path: missing file argument.
expect_fmt_fail_msg "requires a source file argument"

# Non-happy-path: invalid source should fail formatting.
cat >"$tmpdir/fmt_invalid_fail.w" <<'EOF3'
fn main( -> i32 =
    0
EOF3
expect_fmt_parse_fail "$tmpdir/fmt_invalid_fail.w"

if [[ "$failures" -ne 0 ]]; then
  echo "phase6 fmt tests: $failures failure(s)"
  exit 1
fi

echo "phase6 fmt tests: PASS"
