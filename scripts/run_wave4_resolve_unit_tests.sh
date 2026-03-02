#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

SELFHOST_BIN="./with-stage2"

echo "rebuilding self-host compiler for Wave 4 resolve unit tests..."
./scripts/rebuild_selfhost.sh stage2 >/dev/null

if [[ ! -x "$SELFHOST_BIN" ]]; then
  echo "error: missing self-host compiler: $SELFHOST_BIN"
  exit 1
fi

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

run_case() {
  local name="$1"
  local src="$2"
  local out="$tmpdir/${name}.resolved"
  local err="$tmpdir/${name}.stderr"

  if ! "$SELFHOST_BIN" check "$src" --dump-resolved >"$out" 2>"$err"; then
    echo "FAIL(wave4-resolve-unit-check) $src"
    cat "$err"
    failures=$((failures + 1))
    return
  fi

  if ! head -n 1 "$out" | grep -Eq '^resolved root=.* modules=[0-9]+ defs=[0-9]+$'; then
    echo "FAIL(wave4-resolve-unit-header) $src"
    head -n 3 "$out" || true
    failures=$((failures + 1))
    return
  fi

  if ! grep -q '^module\[0\] ' "$out"; then
    echo "FAIL(wave4-resolve-unit-root-module) $src"
    failures=$((failures + 1))
    return
  fi

  if [[ "$name" == "basic" ]]; then
    if ! grep -Eq 'path=.*test/wave4/cases/support/alpha\.w' "$out"; then
      echo "FAIL(wave4-resolve-unit-basic-alpha-import)"
      failures=$((failures + 1))
    fi
    if ! grep -Eq 'path=.*test/wave4/cases/support/beta\.w' "$out"; then
      echo "FAIL(wave4-resolve-unit-basic-beta-import)"
      failures=$((failures + 1))
    fi
  fi

  if [[ "$name" == "cycle" ]]; then
    if ! head -n 1 "$out" | grep -Eq 'modules=3 '; then
      echo "FAIL(wave4-resolve-unit-cycle-module-count)"
      failures=$((failures + 1))
    fi
    if [[ "$(grep -c '^module\[' "$out")" -ne 3 ]]; then
      echo "FAIL(wave4-resolve-unit-cycle-module-lines)"
      failures=$((failures + 1))
    fi
  fi

  if [[ "$name" == "fallback" ]]; then
    if ! grep -Eq 'import\[0:0\] kind=use path=fallback\.pkg\.Item target=[0-9]+' "$out"; then
      echo "FAIL(wave4-resolve-unit-fallback-edge)"
      failures=$((failures + 1))
    fi
    if ! grep -Eq 'path=.*test/wave4/cases/fallback/pkg\.w' "$out"; then
      echo "FAIL(wave4-resolve-unit-fallback-target)"
      failures=$((failures + 1))
    fi
  fi

  if [[ "$name" == "cimport" ]]; then
    if ! grep -q 'kind=c_import header="stdio.h"' "$out"; then
      echo "FAIL(wave4-resolve-unit-cimport-edge)"
      failures=$((failures + 1))
    fi
    if ! grep -q '^link_libs=c$' "$out"; then
      echo "FAIL(wave4-resolve-unit-cimport-link-lib)"
      failures=$((failures + 1))
    fi
  fi

  if [[ "$failures" -eq 0 ]]; then
    echo "PASS(wave4-resolve-unit) $src"
  fi
}

run_case "basic" "test/wave4/cases/basic_root.w"
run_case "cycle" "test/wave4/cases/cycle_root.w"
run_case "fallback" "test/wave4/cases/fallback_root.w"
run_case "cimport" "test/wave4/cases/cimport_root.w"

if [[ "$failures" -ne 0 ]]; then
  echo "wave4 resolve unit tests: $failures failure(s)"
  exit 1
fi

echo "wave4 resolve unit tests: PASS"
