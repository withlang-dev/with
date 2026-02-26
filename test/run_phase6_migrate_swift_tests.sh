#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BIN="./zig-out/bin/with"
echo "building compiler/runtime for phase6 migrate-swift tests..."
zig build -Doptimize=Debug >/dev/null

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

expect_file_contains() {
  local file="$1"
  local pattern="$2"
  if grep -Fq "$pattern" "$file"; then
    echo "PASS(phase6-migrate-swift-contains) $file :: $pattern"
  else
    echo "FAIL(phase6-migrate-swift-contains) $file :: $pattern"
    cat "$file"
    failures=$((failures + 1))
  fi
}

cat >"$tmpdir/sample.swift" <<'EOF1'
protocol Greeter {}
guard let user = currentUser else { return }
let msg = "hello \(user)"
let id: Int? = nil
extension User: Greeter {}
func greet(name: String) -> String {
    return msg
}
EOF1

if "$WITH_BIN" migrate swift "$tmpdir/sample.swift" >"$tmpdir/migrate.out" 2>&1; then
  echo "PASS(phase6-migrate-swift-run)"
else
  echo "FAIL(phase6-migrate-swift-run)"
  cat "$tmpdir/migrate.out"
  failures=$((failures + 1))
fi

if [[ -f "$tmpdir/sample.w" ]]; then
  echo "PASS(phase6-migrate-swift-output-file)"
else
  echo "FAIL(phase6-migrate-swift-output-file)"
  failures=$((failures + 1))
fi

expect_file_contains "$tmpdir/sample.w" "trait Greeter"
expect_file_contains "$tmpdir/sample.w" "let Some(user) = currentUser else return"
expect_file_contains "$tmpdir/sample.w" "\"hello {user}\""
expect_file_contains "$tmpdir/sample.w" "let id: Option[Int] = None"
expect_file_contains "$tmpdir/sample.w" "impl Greeter for User"
expect_file_contains "$tmpdir/sample.w" "fn greet(name: String) -> String:"
expect_file_contains "$tmpdir/migrate.out" "migrate summary:"

# Non-happy-path: manual fixups (`weak`, `@MainActor`) are counted.
cat >"$tmpdir/manual_fixup.swift" <<'EOF2'
@MainActor
class ViewModel {
    weak var delegate: AnyObject?
}
EOF2
if "$WITH_BIN" migrate swift "$tmpdir/manual_fixup.swift" >"$tmpdir/manual.out" 2>&1; then
  echo "PASS(phase6-migrate-swift-manual-run)"
else
  echo "FAIL(phase6-migrate-swift-manual-run)"
  cat "$tmpdir/manual.out"
  failures=$((failures + 1))
fi
expect_file_contains "$tmpdir/manual.out" "manual_fixups=2"

if [[ "$failures" -ne 0 ]]; then
  echo "phase6 migrate-swift tests: $failures failure(s)"
  exit 1
fi

echo "phase6 migrate-swift tests: PASS"
