#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

parity_scripts=(
  "scripts/run_wave2_token_parity.sh"
  "scripts/run_wave3_ast_parity.sh"
  "scripts/run_wave4_resolved_parity.sh"
  "scripts/run_wave5_typed_parity.sh"
  "scripts/run_wave6_typed_parity.sh"
  "scripts/run_wave7_mir_parity.sh"
  "scripts/run_wave8_borrow_parity.sh"
  "scripts/run_wave9_async_parity.sh"
  "scripts/run_wave10_codegen_parity.sh"
  "scripts/run_wave11_driver_parity.sh"
)

total_pass=0
total_fail=0
total_kd=0
overall_rc=0

echo "Wave parity state report"
printf "%-36s %-6s %-6s %-6s %-6s\n" "script" "PASS" "FAIL" "KNOWN" "RC"

for script in "${parity_scripts[@]}"; do
  if [[ ! -x "$script" ]]; then
    continue
  fi

  log_file="$(mktemp)"
  rc=0
  if ! "$script" >"$log_file" 2>&1; then
    rc=$?
    overall_rc=1
  fi

  pass_count="$(grep -c '^PASS(' "$log_file" || true)"
  fail_count="$(grep -c '^FAIL(' "$log_file" || true)"
  kd_count="$(grep -c '^KNOWN_DIVERGENCE(' "$log_file" || true)"

  total_pass=$((total_pass + pass_count))
  total_fail=$((total_fail + fail_count))
  total_kd=$((total_kd + kd_count))

  printf "%-36s %-6s %-6s %-6s %-6s\n" "$script" "$pass_count" "$fail_count" "$kd_count" "$rc"
  rm -f "$log_file"
done

echo ""
echo "TOTAL PASS=$total_pass FAIL=$total_fail KNOWN_DIVERGENCE=$total_kd"

if [[ "$overall_rc" -ne 0 ]]; then
  exit 1
fi
