#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler binary for name-resolution tests..."
zig build -Doptimize=Debug >/dev/null

failures=0

expect_check_pass() {
  local file="$1"
  if "$WITH_BIN" check "$file" >/dev/null 2>/dev/null; then
    echo "PASS(name-check) $file"
  else
    echo "FAIL(name-check) $file"
    failures=$((failures + 1))
  fi
}

expect_check_fail() {
  local file="$1"
  if "$WITH_BIN" check "$file" >/dev/null 2>/dev/null; then
    echo "FAIL(name-check-negative) $file"
    failures=$((failures + 1))
  else
    echo "PASS(name-check-negative) $file"
  fi
}

# Existing positive coverage:
# - locals / params (`locals.w`, `helpers.w`)
# - use-imports (`import_local.w`)
# - prelude symbols (`option_basic.w`)
expect_check_pass "test/cases/locals.w"
expect_check_pass "test/cases/import_local.w"
expect_check_pass "test/cases/option_basic.w"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

# Basic local binding resolution.
cat >"$tmpdir/module_scope.w" <<'EOF'
fn main -> i32:
    let base: i32 = 41
    base + 1
EOF
expect_check_pass "$tmpdir/module_scope.w"

# Prelude symbols should resolve without explicit `use`.
cat >"$tmpdir/prelude_symbols.w" <<'EOF'
fn id[T: Debug + Display + Default + Iter + IntoIter + Eq + Hash + Ord](x: T) -> T:
    x

fn main -> i32:
    let s: String = "with"
    let _opt: Option[str] = Some(s)
    let _res: Result[str, i32] = Ok("ok")
    0
EOF
expect_check_pass "$tmpdir/prelude_symbols.w"

# Local/module names should take precedence over prelude names.
cat >"$tmpdir/prelude_precedence.w" <<'EOF'
fn print(x: i32) -> i32:
    x + 1

fn main -> i32:
    let Vec = 41
    let String = 1
    let Eq = 2
    let a = print(Vec)
    a + String + Eq
EOF
expect_check_pass "$tmpdir/prelude_precedence.w"

# Negative: unresolved local name.
cat >"$tmpdir/unresolved_name.w" <<'EOF'
fn main -> i32:
    missing_name
EOF
expect_check_fail "$tmpdir/unresolved_name.w"

# Negative: unresolved import target.
cat >"$tmpdir/unresolved_import.w" <<'EOF'
use missing_module

fn main -> i32:
    0
EOF
expect_check_fail "$tmpdir/unresolved_import.w"

if [[ "$failures" -ne 0 ]]; then
  echo "phase0 name-resolution tests: $failures failure(s)"
  exit 1
fi

echo "phase0 name-resolution tests: PASS"
