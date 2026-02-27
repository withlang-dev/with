#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

TIMEOUT_SECS="${WITH_AUDIT_TIMEOUT_SECS:-120}"
OUT_BASE="${WITH_AUDIT_OUTDIR:-bootstrap/test/audit}"
STAMP="$(date +"%Y%m%d-%H%M%S")"
OUT_DIR="$OUT_BASE/$STAMP"
SUMMARY="$OUT_DIR/summary.txt"
DETAILS="$OUT_DIR/phase_details.log"
TMP_PHASE_OUT="$OUT_DIR/.tmp_phase_output.txt"
CHECKLIST_UNCHECKED="$OUT_DIR/checklist_unchecked.txt"

mkdir -p "$OUT_DIR"
: >"$SUMMARY"
: >"$DETAILS"

say() {
  printf "%s\n" "$*" | tee -a "$SUMMARY"
}

append_phase_details() {
  local status="$1"
  local script="$2"
  local duration="$3"
  {
    printf "===== %s %s (%ss) =====\n" "$status" "$script" "$duration"
    cat "$TMP_PHASE_OUT"
    printf "\n"
  } >>"$DETAILS"
}

say "With Completeness Audit"
say "date: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
say "root: $ROOT_DIR"
say "timeout_per_phase_script_sec: $TIMEOUT_SECS"
say "artifacts: $OUT_DIR"
say ""

say "[1/4] Checklist sanity (docs/test_checklist.md)"
if [[ ! -f "docs/test_checklist.md" ]]; then
  checklist_open="1"
  printf "MISSING docs/test_checklist.md\n" >"$CHECKLIST_UNCHECKED"
  say "checklist_file: MISSING"
  say "checklist_unchecked: unknown"
else
  if rg -n "^- \\[ \\]" docs/test_checklist.md >"$CHECKLIST_UNCHECKED"; then
    checklist_open="$(wc -l <"$CHECKLIST_UNCHECKED" | tr -d " ")"
    say "checklist_unchecked: $checklist_open"
  else
    checklist_open="0"
    : >"$CHECKLIST_UNCHECKED"
    say "checklist_unchecked: 0"
  fi
fi
say ""

say "[2/4] zig build test"
set +e
zig build test >"$OUT_DIR/zig_build_test.log" 2>&1
unit_rc=$?
set -e
if [[ "$unit_rc" -eq 0 ]]; then
  say "zig_build_test: PASS"
else
  say "zig_build_test: FAIL (rc=$unit_rc)"
fi
say ""

say "[3/4] zig build -Doptimize=Debug"
set +e
zig build -Doptimize=Debug >"$OUT_DIR/zig_build_debug.log" 2>&1
build_rc=$?
set -e
if [[ "$build_rc" -eq 0 ]]; then
  say "zig_build_debug: PASS"
else
  say "zig_build_debug: FAIL (rc=$build_rc)"
fi
say ""

WITH_BIN="./zig-out/bin/with"
if [[ ! -x "$WITH_BIN" ]]; then
  say "binary_present: FAIL ($WITH_BIN missing)"
  build_rc=1
else
  say "binary_present: PASS ($WITH_BIN)"
fi
say ""

say "[4/4] Phase scripts (bootstrap/test/run_phase*.sh)"
phase_total=0
phase_pass=0
phase_fail=0
phase_timeout=0

for script in $(ls bootstrap/test/run_phase*.sh | sort); do
  phase_total=$((phase_total + 1))
  start_ts="$(date +%s)"
  set +e
  timeout -k 5 "$TIMEOUT_SECS" bash "$script" >"$TMP_PHASE_OUT" 2>&1
  rc=$?
  set -e
  end_ts="$(date +%s)"
  duration="$((end_ts - start_ts))"

  if [[ "$rc" -eq 0 ]]; then
    status="PASS"
    phase_pass=$((phase_pass + 1))
  elif [[ "$rc" -eq 124 ]]; then
    status="TIMEOUT"
    phase_timeout=$((phase_timeout + 1))
  else
    status="FAIL"
    phase_fail=$((phase_fail + 1))
  fi

  say "$status $script (${duration}s)"
  append_phase_details "$status" "$script" "$duration"
done

rm -f "$TMP_PHASE_OUT"

say ""
say "phase_scripts_total: $phase_total"
say "phase_scripts_pass: $phase_pass"
say "phase_scripts_fail: $phase_fail"
say "phase_scripts_timeout: $phase_timeout"

say ""
say "Failed/Timed-out scripts:"
FAILED_LIST="$OUT_DIR/failed_scripts.txt"
if rg -n "^(FAIL|TIMEOUT) " "$SUMMARY" >"$FAILED_LIST"; then
  cat "$FAILED_LIST" | tee -a "$SUMMARY"
else
  : >"$FAILED_LIST"
  say "(none)"
fi

say ""
if [[ "$checklist_open" -eq 0 && "$unit_rc" -eq 0 && "$build_rc" -eq 0 && "$phase_fail" -eq 0 && "$phase_timeout" -eq 0 ]]; then
  say "verdict: EVIDENCE_SUPPORTS_COMPLETE"
  exit 0
fi

say "verdict: NOT_PROVEN_COMPLETE"
exit 1
