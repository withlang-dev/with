#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WORKFLOW=".github/workflows/ci.yml"

validate_ci_file() {
  local file="$1"
  grep -q "ubuntu-latest" "$file" || return 1
  grep -q "macos-latest" "$file" || return 1
  grep -q "windows-latest" "$file" || return 1
  grep -q "zig build test" "$file" || return 1
}

failures=0

if validate_ci_file "$WORKFLOW"; then
  echo "PASS(ci-config) $WORKFLOW"
else
  echo "FAIL(ci-config) $WORKFLOW"
  failures=$((failures + 1))
fi

tmp_ok="$(mktemp)"
cat >"$tmp_ok" <<'EOF'
name: CI
jobs:
  unit-tests:
    strategy:
      matrix:
        os: [ubuntu-latest, macos-latest, windows-latest]
    steps:
      - run: zig build test
EOF
if validate_ci_file "$tmp_ok"; then
  echo "PASS(ci-positive) synthetic"
else
  echo "FAIL(ci-positive) synthetic"
  failures=$((failures + 1))
fi
rm -f "$tmp_ok"

tmp_missing_os="$(mktemp)"
cat >"$tmp_missing_os" <<'EOF'
name: CI
jobs:
  unit-tests:
    strategy:
      matrix:
        os: [ubuntu-latest, macos-latest]
    steps:
      - run: zig build test
EOF
if validate_ci_file "$tmp_missing_os"; then
  echo "FAIL(ci-negative) missing windows unexpectedly validated"
  failures=$((failures + 1))
else
  echo "PASS(ci-negative) missing windows rejected"
fi
rm -f "$tmp_missing_os"

tmp_missing_cmd="$(mktemp)"
cat >"$tmp_missing_cmd" <<'EOF'
name: CI
jobs:
  unit-tests:
    strategy:
      matrix:
        os: [ubuntu-latest, macos-latest, windows-latest]
    steps:
      - run: zig fmt .
EOF
if validate_ci_file "$tmp_missing_cmd"; then
  echo "FAIL(ci-negative) missing test command unexpectedly validated"
  failures=$((failures + 1))
else
  echo "PASS(ci-negative) missing test command rejected"
fi
rm -f "$tmp_missing_cmd"

if [[ "$failures" -ne 0 ]]; then
  echo "phase0 CI tests: $failures failure(s)"
  exit 1
fi

echo "phase0 CI tests: PASS"
