#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

SCRIPT_TIMEOUT_SECS="${WAVE_SCRIPT_TIMEOUT_SECS:-1800}"
CURRENT_SCRIPT_PID=""

kill_tree() {
  local pid="$1"
  local signal_name="$2"
  local child=""
  local children=""

  children="$(pgrep -P "$pid" 2>/dev/null || true)"
  for child in $children; do
    kill_tree "$child" "$signal_name"
  done
  kill "-${signal_name}" "$pid" 2>/dev/null || kill -"$signal_name" "$pid" 2>/dev/null || true
}

handle_interrupt() {
  if [[ -n "$CURRENT_SCRIPT_PID" ]]; then
    kill_tree "$CURRENT_SCRIPT_PID" TERM
    sleep 1
    kill_tree "$CURRENT_SCRIPT_PID" KILL
  fi
  echo "run_all_wave_tests: interrupted"
  exit 130
}

trap handle_interrupt INT TERM

run_script() {
  local script="$1"
  local start_time=0
  local now=0
  local elapsed=0

  "$script" &
  CURRENT_SCRIPT_PID=$!
  start_time="$(date +%s)"

  while kill -0 "$CURRENT_SCRIPT_PID" 2>/dev/null; do
    if [[ "$SCRIPT_TIMEOUT_SECS" -gt 0 ]]; then
      now="$(date +%s)"
      elapsed=$((now - start_time))
      if [[ "$elapsed" -ge "$SCRIPT_TIMEOUT_SECS" ]]; then
        echo "FAIL(run-all-timeout) $script timeout=${SCRIPT_TIMEOUT_SECS}s"
        kill_tree "$CURRENT_SCRIPT_PID" TERM
        sleep 1
        kill_tree "$CURRENT_SCRIPT_PID" KILL
        CURRENT_SCRIPT_PID=""
        return 124
      fi
    fi
    sleep 0.2
  done

  wait "$CURRENT_SCRIPT_PID"
  local rc=$?
  CURRENT_SCRIPT_PID=""
  return "$rc"
}

scripts=(
  "scripts/run_wave1_unit_tests.sh"
  "scripts/run_wave2_lexer_unit_tests.sh"
  "scripts/run_wave2_token_parity.sh"
  "scripts/run_wave3_parser_unit_tests.sh"
  "scripts/run_wave3_ast_parity.sh"
  "scripts/run_wave4_resolve_unit_tests.sh"
  "scripts/run_wave4_resolved_parity.sh"
  "scripts/run_wave5_type_trait_unit_tests.sh"
  "scripts/run_wave5_typed_parity.sh"
  "scripts/run_wave6_sema_unit_tests.sh"
  "scripts/run_wave6_typed_parity.sh"
  "scripts/run_wave7_mir_unit_tests.sh"
  "scripts/run_wave7_mir_parity.sh"
  "scripts/run_wave8_borrow_unit_tests.sh"
  "scripts/run_wave8_borrow_parity.sh"
  "scripts/run_wave9_async_unit_tests.sh"
  "scripts/run_wave9_async_parity.sh"
  "scripts/run_wave10_codegen_unit_tests.sh"
  "scripts/run_wave10_codegen_parity.sh"
)

if [[ -x "scripts/run_cli_selfhost_tests.sh" ]]; then
  scripts+=("scripts/run_cli_selfhost_tests.sh")
fi
if [[ -x "scripts/run_wave11_driver_parity.sh" ]]; then
  scripts+=("scripts/run_wave11_driver_parity.sh")
fi
if [[ -x "scripts/run_wave12_selfhost_fixpoint.sh" ]]; then
  scripts+=("scripts/run_wave12_selfhost_fixpoint.sh")
fi

for script in "${scripts[@]}"; do
  echo "=== running: $script ==="
  run_script "$script"
  echo ""
done

echo "all wave test harnesses: PASS"
