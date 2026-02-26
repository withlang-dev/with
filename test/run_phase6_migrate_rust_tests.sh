#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler/runtime for phase6 migrate-rust tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_file_contains() {
  local file="$1"
  local pattern="$2"
  if grep -Fq "$pattern" "$file"; then
    echo "PASS(phase6-migrate-rust-contains) $file :: $pattern"
  else
    echo "FAIL(phase6-migrate-rust-contains) $file :: $pattern"
    cat "$file"
    failures=$((failures + 1))
  fi
}

cat >"$tmpdir/sample.rs" <<'EOF1'
#[derive(Clone)]
fn main() {
    let mut x = 1;
    println!("{}", x);
    let s = String::from("abc");
    let u = Ok(());
}
EOF1

if "$WITH_BIN" migrate rust "$tmpdir/sample.rs" >"$tmpdir/migrate.out" 2>&1; then
  echo "PASS(phase6-migrate-rust-run)"
else
  echo "FAIL(phase6-migrate-rust-run)"
  cat "$tmpdir/migrate.out"
  failures=$((failures + 1))
fi

if [[ -f "$tmpdir/sample.w" ]]; then
  echo "PASS(phase6-migrate-rust-output-file)"
else
  echo "FAIL(phase6-migrate-rust-output-file)"
  failures=$((failures + 1))
fi

expect_file_contains "$tmpdir/sample.w" "@[derive(Clone)]"
expect_file_contains "$tmpdir/sample.w" "var x = 1"
expect_file_contains "$tmpdir/sample.w" "println(\"{x}\")"
expect_file_contains "$tmpdir/sample.w" "let s = \"abc\""
expect_file_contains "$tmpdir/sample.w" "let u = Ok()"
expect_file_contains "$tmpdir/migrate.out" "migrate summary:"

# Non-happy-path: rust manual-fixup hints should be counted.
cat >"$tmpdir/manual_fixup.rs" <<'EOF2'
fn use_pin(x: Pin<Box<i32>>) -> i32 {
    x
}
EOF2
if "$WITH_BIN" migrate rust "$tmpdir/manual_fixup.rs" >"$tmpdir/manual.out" 2>&1; then
  echo "PASS(phase6-migrate-rust-manual-run)"
else
  echo "FAIL(phase6-migrate-rust-manual-run)"
  cat "$tmpdir/manual.out"
  failures=$((failures + 1))
fi
expect_file_contains "$tmpdir/manual.out" "manual_fixups=1"

# Non-happy-path: --check should fail when output would change.
cat >"$tmpdir/check_fail.rs" <<'EOF3'
fn main() {
    let mut y = 3;
}
EOF3
if "$WITH_BIN" migrate rust "$tmpdir/check_fail.rs" --check >"$tmpdir/check.out" 2>&1; then
  echo "FAIL(phase6-migrate-rust-check-should-fail)"
  cat "$tmpdir/check.out"
  failures=$((failures + 1))
else
  echo "PASS(phase6-migrate-rust-check-fail)"
  expect_file_contains "$tmpdir/check.out" "would migrate"
fi

if [[ "$failures" -ne 0 ]]; then
  echo "phase6 migrate-rust tests: $failures failure(s)"
  exit 1
fi

echo "phase6 migrate-rust tests: PASS"
