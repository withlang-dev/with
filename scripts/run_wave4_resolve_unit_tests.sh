#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
source "${ROOT_DIR}/scripts/selfhost_runner.sh"

SELFHOST_BIN="./with-stage2"
CHECK_TIMEOUT_SECS="${PARITY_CHECK_TIMEOUT_SECS:-60}"

echo "rebuilding self-host compiler for Wave 4 resolve unit tests..."
./scripts/rebuild_selfhost.sh stage2 >/dev/null

if [[ ! -x "$SELFHOST_BIN" ]]; then
  echo "error: missing self-host compiler: $SELFHOST_BIN"
  exit 1
fi

SELFHOST_BIN="$(prepare_selfhost_runner "$ROOT_DIR" "$SELFHOST_BIN")"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"; cleanup_selfhost_runner' EXIT

failures=0

run_case() {
  local name="$1"
  local src="$2"
  local out="$tmpdir/${name}.resolved"
  local err="$tmpdir/${name}.stderr"
  local case_failures=0

  if ! runner_exec_capture "$CHECK_TIMEOUT_SECS" "$out" "$err" "$SELFHOST_BIN" check "$src" --dump-resolved; then
    echo "FAIL(wave4-resolve-unit-check) $src"
    cat "$err"
    failures=$((failures + 1))
    return
  fi

  if ! head -n 1 "$out" | grep -Eq '^resolved root=.* modules=[0-9]+ defs=[0-9]+$'; then
    echo "FAIL(wave4-resolve-unit-header) $src"
    head -n 3 "$out" || true
    case_failures=$((case_failures + 1))
  fi

  if ! grep -q '^module\[0\] ' "$out"; then
    echo "FAIL(wave4-resolve-unit-root-module) $src"
    case_failures=$((case_failures + 1))
  fi

  if [[ "$name" == "basic" ]]; then
    if ! grep -Eq 'path=.*test/wave4/cases/support/alpha\.w' "$out"; then
      echo "FAIL(wave4-resolve-unit-basic-alpha-import) $src"
      case_failures=$((case_failures + 1))
    fi
    if ! grep -Eq 'path=.*test/wave4/cases/support/beta\.w' "$out"; then
      echo "FAIL(wave4-resolve-unit-basic-beta-import) $src"
      case_failures=$((case_failures + 1))
    fi
  fi

  if [[ "$name" == "cycle" ]]; then
    if ! head -n 1 "$out" | grep -Eq 'modules=3 '; then
      echo "FAIL(wave4-resolve-unit-cycle-module-count) $src"
      case_failures=$((case_failures + 1))
    fi
    if [[ "$(grep -c '^module\[' "$out")" -ne 3 ]]; then
      echo "FAIL(wave4-resolve-unit-cycle-module-lines) $src"
      case_failures=$((case_failures + 1))
    fi
  fi

  if [[ "$name" == "fallback" ]]; then
    if ! grep -Eq 'import\[0:0\] kind=use path=fallback\.pkg\.Item target=[0-9]+' "$out"; then
      echo "FAIL(wave4-resolve-unit-fallback-edge) $src"
      case_failures=$((case_failures + 1))
    fi
    if ! grep -Eq 'path=.*test/wave4/cases/fallback/pkg\.w' "$out"; then
      echo "FAIL(wave4-resolve-unit-fallback-target) $src"
      case_failures=$((case_failures + 1))
    fi
  fi

  if [[ "$name" == "cimport" ]]; then
    if ! grep -q 'kind=c_import header="stdio.h"' "$out"; then
      echo "FAIL(wave4-resolve-unit-cimport-edge) $src"
      case_failures=$((case_failures + 1))
    fi
    if ! grep -q '^link_libs=c$' "$out"; then
      echo "FAIL(wave4-resolve-unit-cimport-link-lib) $src"
      case_failures=$((case_failures + 1))
    fi
  fi

  if [[ "$name" == "duplicate_import" ]]; then
    # Duplicate imports should resolve to the same module target (deduped graph node).
    if ! head -n 1 "$out" | grep -Eq 'modules=2 '; then
      echo "FAIL(wave4-resolve-unit-duplicate-import-module-count) $src"
      case_failures=$((case_failures + 1))
    fi
    local target_a target_b
    target_a="$(grep 'import\[0:0\]' "$out" | grep -o 'target=[0-9]*' | head -1)"
    target_b="$(grep 'import\[0:1\]' "$out" | grep -o 'target=[0-9]*' | head -1)"
    if [[ -z "$target_a" || "$target_a" != "$target_b" ]]; then
      echo "FAIL(wave4-resolve-unit-duplicate-import-target-match) $src target_a=$target_a target_b=$target_b"
      case_failures=$((case_failures + 1))
    fi
  fi

  if [[ "$name" == "alias_cycle" ]]; then
    if ! head -n 1 "$out" | grep -Eq 'modules=3 '; then
      echo "FAIL(wave4-resolve-unit-alias-cycle-module-count) $src"
      case_failures=$((case_failures + 1))
    fi
    if [[ "$(grep -c 'alias_cycle/left\.w' "$out")" -ne 1 ]]; then
      echo "FAIL(wave4-resolve-unit-alias-cycle-left-dedup) $src"
      case_failures=$((case_failures + 1))
    fi
    if [[ "$(grep -c 'alias_cycle/right\.w' "$out")" -ne 1 ]]; then
      echo "FAIL(wave4-resolve-unit-alias-cycle-right-dedup) $src"
      case_failures=$((case_failures + 1))
    fi
  fi

  if [[ "$name" == "cimport_links" ]]; then
    if ! grep -q 'kind=c_import header="stdio.h"' "$out"; then
      echo "FAIL(wave4-resolve-unit-cimport-links-stdio) $src"
      case_failures=$((case_failures + 1))
    fi
    if ! grep -q 'kind=c_import header="string.h"' "$out"; then
      echo "FAIL(wave4-resolve-unit-cimport-links-string) $src"
      case_failures=$((case_failures + 1))
    fi
    if ! grep -q '^link_libs=m,c$' "$out"; then
      echo "FAIL(wave4-resolve-unit-cimport-links-order-dedup) $src"
      case_failures=$((case_failures + 1))
    fi
  fi

  if [[ "$name" == "diamond" ]]; then
    # Diamond: root -> left + right, both -> shared. Must be 4 modules.
    if ! head -n 1 "$out" | grep -Eq 'modules=4 '; then
      echo "FAIL(wave4-resolve-unit-diamond-module-count) $src"
      case_failures=$((case_failures + 1))
    fi
    # shared.w must appear exactly once (deduplication).
    if [[ "$(grep -c 'diamond/shared\.w' "$out")" -ne 1 ]]; then
      echo "FAIL(wave4-resolve-unit-diamond-shared-dedup) $src"
      case_failures=$((case_failures + 1))
    fi
    # Both left and right must import shared with same target id.
    local left_target right_target
    left_target="$(grep 'import\[1:0\].*diamond\.shared' "$out" | grep -o 'target=[0-9]*' | head -1)"
    right_target="$(grep 'import\[2:0\].*diamond\.shared' "$out" | grep -o 'target=[0-9]*' | head -1)"
    if [[ -z "$left_target" || "$left_target" != "$right_target" ]]; then
      echo "FAIL(wave4-resolve-unit-diamond-target-match) $src left=$left_target right=$right_target"
      case_failures=$((case_failures + 1))
    fi
  fi

  if [[ "$name" == "deep" ]]; then
    # Deep: 3 levels of nesting (deep/level1/level2/leaf.w).
    if ! grep -q 'deep/level1/level2/leaf\.w' "$out"; then
      echo "FAIL(wave4-resolve-unit-deep-leaf-path) $src"
      case_failures=$((case_failures + 1))
    fi
    if ! head -n 1 "$out" | grep -Eq 'modules=2 '; then
      echo "FAIL(wave4-resolve-unit-deep-module-count) $src"
      case_failures=$((case_failures + 1))
    fi
  fi

  if [[ "$name" == "multi_import" ]]; then
    # Multi-import: root imports alpha, beta, and shared from different dirs.
    if ! head -n 1 "$out" | grep -Eq 'modules=4 '; then
      echo "FAIL(wave4-resolve-unit-multi-import-module-count) $src"
      case_failures=$((case_failures + 1))
    fi
    if ! grep -q 'support/alpha\.w' "$out"; then
      echo "FAIL(wave4-resolve-unit-multi-import-alpha) $src"
      case_failures=$((case_failures + 1))
    fi
    if ! grep -q 'diamond/shared\.w' "$out"; then
      echo "FAIL(wave4-resolve-unit-multi-import-shared) $src"
      case_failures=$((case_failures + 1))
    fi
  fi

  if [[ "$name" == "types" ]]; then
    # Cross-module types: imported module defines types + functions.
    if ! grep -q 'types/defs\.w' "$out"; then
      echo "FAIL(wave4-resolve-unit-types-defs-path) $src"
      case_failures=$((case_failures + 1))
    fi
    # Should have defs for Shape, Point, origin, describe, main, Circle, Rect, etc.
    local def_count
    def_count="$(head -n 1 "$out" | grep -o 'defs=[0-9]*' | cut -d= -f2)"
    if [[ "$def_count" -lt 5 ]]; then
      echo "FAIL(wave4-resolve-unit-types-def-count) $src defs=$def_count"
      case_failures=$((case_failures + 1))
    fi
  fi

  if [[ "$case_failures" -eq 0 ]]; then
    echo "PASS(wave4-resolve-unit) $src"
  else
    failures=$((failures + case_failures))
  fi
}

run_error_case() {
  local name="$1"
  local src="$2"
  local expected_pattern="$3"
  local out="$tmpdir/${name}.resolved"
  local err="$tmpdir/${name}.stderr"
  local case_failures=0

  local rc=0
  runner_exec_capture "$CHECK_TIMEOUT_SECS" "$out" "$err" "$SELFHOST_BIN" check "$src" --dump-resolved || rc=$?
  if [[ "$rc" -eq 0 ]]; then
    echo "FAIL(wave4-resolve-unit-expected-error) $src (expected non-zero exit)"
    case_failures=$((case_failures + 1))
  else
    if [[ -n "$expected_pattern" ]] && ! grep -q "$expected_pattern" "$err"; then
      echo "FAIL(wave4-resolve-unit-error-pattern) $src (expected: $expected_pattern)"
      cat "$err"
      case_failures=$((case_failures + 1))
    fi
  fi

  if [[ "$case_failures" -eq 0 ]]; then
    echo "PASS(wave4-resolve-unit-error) $src"
  else
    failures=$((failures + case_failures))
  fi
}

run_golden_case() {
  local name="$1"
  local src="$2"
  local golden="$3"
  local out="$tmpdir/${name}.golden.out"
  local err="$tmpdir/${name}.golden.err"

  if [[ ! -f "$golden" ]]; then
    echo "FAIL(wave4-resolve-unit-golden-missing) $src golden=$golden"
    failures=$((failures + 1))
    return
  fi
  if ! runner_exec_capture "$CHECK_TIMEOUT_SECS" "$out" "$err" "$SELFHOST_BIN" check "$src" --dump-resolved; then
    echo "FAIL(wave4-resolve-unit-golden-check) $src"
    cat "$err" || true
    failures=$((failures + 1))
    return
  fi
  if ! diff -u "$golden" "$out" >/dev/null; then
    echo "FAIL(wave4-resolve-unit-golden-diff) $src"
    diff -u "$golden" "$out" || true
    failures=$((failures + 1))
    return
  fi
  echo "PASS(wave4-resolve-unit-golden) $src"
}

run_case "basic" "test/wave4/cases/basic_root.w"
run_case "cycle" "test/wave4/cases/cycle_root.w"
run_case "fallback" "test/wave4/cases/fallback_root.w"
run_case "cimport" "test/wave4/cases/cimport_root.w"
run_error_case "unresolved_import" "test/wave4/cases/unresolved_import.w" "import module not found"

# --- New multi-module scenario tests ---

run_case "diamond" "test/wave4/cases/diamond_root.w"
run_case "deep" "test/wave4/cases/deep_root.w"
run_case "multi_import" "test/wave4/cases/multi_import_root.w"
run_case "types" "test/wave4/cases/types_root.w"
run_case "duplicate_import" "test/wave4/cases/duplicate_import_root.w"
run_case "alias_cycle" "test/wave4/cases/alias_cycle_root.w"
run_case "cimport_links" "test/wave4/cases/cimport_links_root.w"
run_error_case "multi_error" "test/wave4/cases/multi_error.w" "import module not found"
run_error_case "nested_missing" "test/wave4/cases/nested_missing_root.w" "import module not found"

run_golden_case "types_golden" "test/wave4/cases/types_root.w" "test/wave4/golden/types_root.resolved.txt"
run_golden_case "diamond_golden" "test/wave4/cases/diamond_root.w" "test/wave4/golden/diamond_root.resolved.txt"

if [[ "$failures" -ne 0 ]]; then
  echo "wave4 resolve unit tests: $failures failure(s)"
  exit 1
fi

echo "wave4 resolve unit tests: PASS"
