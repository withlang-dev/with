#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler/runtime for phase6 migrate-zig tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_file_contains() {
  local file="$1"
  local pattern="$2"
  if grep -Fq "$pattern" "$file"; then
    echo "PASS(phase6-migrate-zig-contains) $file :: $pattern"
  else
    echo "FAIL(phase6-migrate-zig-contains) $file :: $pattern"
    cat "$file"
    failures=$((failures + 1))
  fi
}

cat >"$tmpdir/sample.zig" <<'EOF1'
const x: i32 = @as(i32, 1);
const y = try maybe();
const z = x orelse 0;
const n = null;
fn add(a: i32, b: i32) i32 { return a + b; }
EOF1

if "$WITH_BIN" migrate zig "$tmpdir/sample.zig" >"$tmpdir/migrate.out" 2>&1; then
  echo "PASS(phase6-migrate-zig-run)"
else
  echo "FAIL(phase6-migrate-zig-run)"
  cat "$tmpdir/migrate.out"
  failures=$((failures + 1))
fi

if [[ -f "$tmpdir/sample.w" ]]; then
  echo "PASS(phase6-migrate-zig-output-file)"
else
  echo "FAIL(phase6-migrate-zig-output-file)"
  failures=$((failures + 1))
fi

expect_file_contains "$tmpdir/sample.w" "let x: i32 = 1 as i32"
expect_file_contains "$tmpdir/sample.w" "let y = maybe()?"
expect_file_contains "$tmpdir/sample.w" "let z = x ?? 0"
expect_file_contains "$tmpdir/sample.w" "let n = None"
expect_file_contains "$tmpdir/sample.w" "fn add(a: i32, b: i32) -> i32 = a + b"
expect_file_contains "$tmpdir/migrate.out" "migrate summary:"

# Non-happy-path: manual fixups (`undefined`, `errdefer`) are reported.
cat >"$tmpdir/manual_fixup.zig" <<'EOF2'
const x = undefined;
errdefer cleanup();
EOF2
if "$WITH_BIN" migrate zig "$tmpdir/manual_fixup.zig" >"$tmpdir/manual.out" 2>&1; then
  echo "PASS(phase6-migrate-zig-manual-run)"
else
  echo "FAIL(phase6-migrate-zig-manual-run)"
  cat "$tmpdir/manual.out"
  failures=$((failures + 1))
fi
expect_file_contains "$tmpdir/manual.out" "manual_fixups=2"

if [[ "$failures" -ne 0 ]]; then
  echo "phase6 migrate-zig tests: $failures failure(s)"
  exit 1
fi

echo "phase6 migrate-zig tests: PASS"
