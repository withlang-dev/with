#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

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

if [[ -x "scripts/run_wave11_driver_unit_tests.sh" ]]; then
  scripts+=("scripts/run_wave11_driver_unit_tests.sh")
fi
if [[ -x "scripts/run_wave11_driver_parity.sh" ]]; then
  scripts+=("scripts/run_wave11_driver_parity.sh")
fi

for script in "${scripts[@]}"; do
  echo "=== running: $script ==="
  "$script"
  echo ""
done

echo "all wave test harnesses: PASS"
