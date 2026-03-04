#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

MANIFEST="test/wave10/coverage_manifest.txt"
CORPUS="test/wave10/codegen_corpus.txt"

if [[ ! -f "$MANIFEST" ]]; then
  echo "error: missing Wave 10 coverage manifest: $MANIFEST"
  exit 1
fi
if [[ ! -f "$CORPUS" ]]; then
  echo "error: missing Wave 10 corpus: $CORPUS"
  exit 1
fi

required_scripts=(
  "run_phase0_llvm_codegen_tests.sh"
  "run_phase0_llvm_verify_ir_tests.sh"
  "run_phase2_monomorphization_tests.sh"
  "run_phase2_generic_function_definition_tests.sh"
  "run_phase2_generic_type_definition_tests.sh"
  "run_phase2_generic_inference_tests.sh"
  "run_phase2_unused_instantiation_tests.sh"
  "run_phase2_enum_accessors_tests.sh"
  "run_phase2_enum_variant_shorthand_tests.sh"
  "run_phase5_dyn_trait_vtable_tests.sh"
  "run_phase5_devirtualization_tests.sh"
  "run_phase5_box_ref_dyn_tests.sh"
  "run_phase5_object_safety_diagnostics_tests.sh"
)

trim() {
  local s="$1"
  s="$(echo "$s" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')"
  echo "$s"
}

corpus_has_entry() {
  local mode="$1"
  local path="$2"
  grep -Fqx "${mode}|${path}" "$CORPUS"
}

corpus_has_kd_entry() {
  local mode="$1"
  local path="$2"
  grep -Fq "KNOWN_DIVERGENCE|${mode}|${path}|" "$CORPUS"
}

seen_file="$(mktemp)"
trap 'rm -f "$seen_file"' EXIT
failures=0
processed=0

while IFS= read -r raw_line; do
  line="$(trim "$raw_line")"
  [[ -z "$line" ]] && continue
  [[ "${line:0:1}" == "#" ]] && continue

  IFS='|' read -r script status evidence note <<<"$line"
  script="$(trim "$script")"
  status="$(trim "$status")"
  evidence="$(trim "$evidence")"

  if [[ -z "$script" || -z "$status" || -z "$evidence" ]]; then
    echo "FAIL(wave10-coverage-manifest-format) $line"
    failures=$((failures + 1))
    continue
  fi

  echo "$script" >>"$seen_file"
  processed=$((processed + 1))

  if [[ "$status" != "covered" && "$status" != "known_divergence" ]]; then
    echo "FAIL(wave10-coverage-status) $script status='$status'"
    failures=$((failures + 1))
    continue
  fi

  has_covered=0
  has_kd=0
  IFS=',' read -r -a evidence_items <<<"$evidence"
  if [[ "${#evidence_items[@]}" -eq 0 ]]; then
    echo "FAIL(wave10-coverage-evidence-empty) $script"
    failures=$((failures + 1))
    continue
  fi

  for item_raw in "${evidence_items[@]}"; do
    item="$(trim "$item_raw")"
    if [[ "$item" != *:* ]]; then
      echo "FAIL(wave10-coverage-evidence-format) $script item='$item'"
      failures=$((failures + 1))
      continue
    fi

    mode="${item%%:*}"
    path="${item#*:}"
    mode="$(trim "$mode")"
    path="$(trim "$path")"

    if [[ "$mode" != "check" && "$mode" != "ir" && "$mode" != "build" && "$mode" != "run" ]]; then
      echo "FAIL(wave10-coverage-evidence-mode) $script mode='$mode'"
      failures=$((failures + 1))
      continue
    fi
    if [[ ! -f "$path" ]]; then
      echo "FAIL(wave10-coverage-evidence-missing-file) $script ${mode}:${path}"
      failures=$((failures + 1))
      continue
    fi

    if corpus_has_kd_entry "$mode" "$path"; then
      has_kd=1
      continue
    fi
    if corpus_has_entry "$mode" "$path"; then
      has_covered=1
      continue
    fi

    echo "FAIL(wave10-coverage-evidence-missing-corpus-entry) $script ${mode}:${path}"
    failures=$((failures + 1))
  done

  if [[ "$status" == "covered" && "$has_covered" -eq 0 ]]; then
    echo "FAIL(wave10-coverage-covered-without-covered-evidence) $script"
    failures=$((failures + 1))
  fi
  if [[ "$status" == "known_divergence" && "$has_kd" -eq 0 ]]; then
    echo "FAIL(wave10-coverage-kd-without-kd-evidence) $script"
    failures=$((failures + 1))
  fi
done <"$MANIFEST"

for req in "${required_scripts[@]}"; do
  if ! grep -Fqx "$req" "$seen_file"; then
    echo "FAIL(wave10-coverage-missing-required-script) $req"
    failures=$((failures + 1))
  fi
done

if [[ "$processed" -eq 0 ]]; then
  echo "FAIL(wave10-coverage-empty-manifest) $MANIFEST"
  exit 1
fi

if [[ "$failures" -ne 0 ]]; then
  echo "wave10 coverage verification: FAIL (processed=$processed failures=$failures)"
  exit 1
fi

echo "wave10 coverage verification: PASS (processed=$processed)"
