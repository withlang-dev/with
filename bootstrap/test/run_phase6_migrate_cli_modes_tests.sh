#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler/runtime for phase6 migrate-cli tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_file_contains() {
  local file="$1"
  local pattern="$2"
  if grep -Fq -- "$pattern" "$file"; then
    echo "PASS(phase6-migrate-cli-contains) $file :: $pattern"
  else
    echo "FAIL(phase6-migrate-cli-contains) $file :: $pattern"
    cat "$file"
    failures=$((failures + 1))
  fi
}

mkdir -p "$tmpdir/src"
cat >"$tmpdir/src/app.rs" <<'EOF1'
fn main() {
    let mut x = 1;
}
EOF1

# --check: should fail when output differs/missing.
if "$WITH_BIN" migrate rust "$tmpdir/src" --check >"$tmpdir/check1.out" 2>&1; then
  echo "FAIL(phase6-migrate-cli-check-should-fail)"
  cat "$tmpdir/check1.out"
  failures=$((failures + 1))
else
  echo "PASS(phase6-migrate-cli-check-fails-on-pending)"
  expect_file_contains "$tmpdir/check1.out" "would migrate"
fi

# Write mode then check mode should pass.
if "$WITH_BIN" migrate rust "$tmpdir/src" >"$tmpdir/write.out" 2>&1; then
  echo "PASS(phase6-migrate-cli-write)"
else
  echo "FAIL(phase6-migrate-cli-write)"
  cat "$tmpdir/write.out"
  failures=$((failures + 1))
fi

if "$WITH_BIN" migrate rust "$tmpdir/src" --check >"$tmpdir/check2.out" 2>&1; then
  echo "PASS(phase6-migrate-cli-check-clean)"
else
  echo "FAIL(phase6-migrate-cli-check-clean)"
  cat "$tmpdir/check2.out"
  failures=$((failures + 1))
fi

# --diff: should emit before/after headings and changed lines.
cat >"$tmpdir/src/app.rs" <<'EOF2'
fn main() {
    let mut x = 2;
}
EOF2
if "$WITH_BIN" migrate rust "$tmpdir/src/app.rs" --diff >"$tmpdir/diff.out" 2>&1; then
  echo "PASS(phase6-migrate-cli-diff)"
else
  echo "FAIL(phase6-migrate-cli-diff)"
  cat "$tmpdir/diff.out"
  failures=$((failures + 1))
fi
expect_file_contains "$tmpdir/diff.out" "--- $tmpdir/src/app.rs"
expect_file_contains "$tmpdir/diff.out" "+++ $tmpdir/src/app.w"
expect_file_contains "$tmpdir/diff.out" "+    var x = 2"

# Non-happy-path: mutually exclusive flags should fail.
if "$WITH_BIN" migrate rust "$tmpdir/src/app.rs" --check --diff >"$tmpdir/bad_flags.out" 2>&1; then
  echo "FAIL(phase6-migrate-cli-exclusive-flags)"
  cat "$tmpdir/bad_flags.out"
  failures=$((failures + 1))
else
  echo "PASS(phase6-migrate-cli-exclusive-flags)"
  expect_file_contains "$tmpdir/bad_flags.out" "choose only one"
fi

# Non-happy-path: unknown language should fail.
if "$WITH_BIN" migrate java "$tmpdir/src" >"$tmpdir/bad_lang.out" 2>&1; then
  echo "FAIL(phase6-migrate-cli-unknown-lang)"
  cat "$tmpdir/bad_lang.out"
  failures=$((failures + 1))
else
  echo "PASS(phase6-migrate-cli-unknown-lang)"
  expect_file_contains "$tmpdir/bad_lang.out" "unsupported migrate language"
fi

if [[ "$failures" -ne 0 ]]; then
  echo "phase6 migrate-cli tests: $failures failure(s)"
  exit 1
fi

echo "phase6 migrate-cli tests: PASS"
