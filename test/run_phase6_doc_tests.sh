#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler/runtime for phase6 doc tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_doc_contains() {
  local file="$1"
  local pattern="$2"
  local out_file="$tmpdir/doc.out.$$"
  if "$WITH_BIN" doc "$file" >"$out_file" 2>"$tmpdir/stderr.$$"; then
    if grep -Fq "$pattern" "$out_file"; then
      echo "PASS(phase6-doc-contains) $file :: $pattern"
    else
      echo "FAIL(phase6-doc-contains) $file :: $pattern"
      cat "$out_file"
      failures=$((failures + 1))
    fi
  else
    echo "FAIL(phase6-doc-run) $file"
    cat "$tmpdir/stderr.$$"
    failures=$((failures + 1))
  fi
  rm -f "$out_file" "$tmpdir/stderr.$$"
}

expect_doc_fail_msg() {
  local msg="$1"
  local stderr_file="$tmpdir/doc.err.$$"
  if "$WITH_BIN" doc >/dev/null 2>"$stderr_file"; then
    echo "FAIL(phase6-doc-fail)"
    failures=$((failures + 1))
  else
    if grep -Fq "$msg" "$stderr_file"; then
      echo "PASS(phase6-doc-fail)"
    else
      echo "FAIL(phase6-doc-fail-msg)"
      cat "$stderr_file"
      failures=$((failures + 1))
    fi
  fi
  rm -f "$stderr_file"
}

expect_doc_parse_fail() {
  local file="$1"
  if "$WITH_BIN" doc "$file" >/dev/null 2>"$tmpdir/stderr.$$"; then
    echo "FAIL(phase6-doc-parse-fail) $file"
    failures=$((failures + 1))
  else
    echo "PASS(phase6-doc-parse-fail) $file"
  fi
  rm -f "$tmpdir/stderr.$$"
}

# Positive: index + cross-links + example extraction.
cat >"$tmpdir/doc_index_examples_ok.w" <<'EOF1'
// User record for docs.
// example: let user = User { id: 1 }
type User = {
    id: i32,
}

// Returns a deterministic answer.
fn answer() -> i32 = 42
EOF1
expect_doc_contains "$tmpdir/doc_index_examples_ok.w" "## Index"
expect_doc_contains "$tmpdir/doc_index_examples_ok.w" '[type `User`](#type-User)'
expect_doc_contains "$tmpdir/doc_index_examples_ok.w" '[fn `answer`](#fn-answer)'
expect_doc_contains "$tmpdir/doc_index_examples_ok.w" '<a id="type-User"></a>'
expect_doc_contains "$tmpdir/doc_index_examples_ok.w" '<a id="fn-answer"></a>'
expect_doc_contains "$tmpdir/doc_index_examples_ok.w" "**Example**"
expect_doc_contains "$tmpdir/doc_index_examples_ok.w" "let user = User { id: 1 }"

# Non-happy-path: missing file argument.
expect_doc_fail_msg "requires a source file argument"

# Non-happy-path: invalid source should fail doc generation.
cat >"$tmpdir/doc_invalid_fail.w" <<'EOF2'
fn answer( -> i32 = 42
EOF2
expect_doc_parse_fail "$tmpdir/doc_invalid_fail.w"

if [[ "$failures" -ne 0 ]]; then
  echo "phase6 doc tests: $failures failure(s)"
  exit 1
fi

echo "phase6 doc tests: PASS"
