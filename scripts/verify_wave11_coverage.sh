#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

MANIFEST="test/wave11/coverage_manifest.txt"
CORPUS="test/wave11/driver_corpus.txt"

if [[ ! -f "$MANIFEST" ]]; then
  echo "error: missing Wave 11 coverage manifest: $MANIFEST"
  exit 1
fi
if [[ ! -f "$CORPUS" ]]; then
  echo "error: missing Wave 11 corpus: $CORPUS"
  exit 1
fi

required_scripts=(
  "run_phase0_driver_commands_tests.sh"
  "run_phase0_object_link_tests.sh"
  "run_phase0_import_path_regression_tests.sh"
  "run_phase0_c_import_tests.sh"
  "run_phase0_c_import_link_tests.sh"
  "run_phase0_c_import_cache_tests.sh"
  "run_phase0_c_import_milestone_tests.sh"
  "run_phase6_c_import_cache_invalidation_tests.sh"
  "run_phase6_c_import_macro_diagnostics_tests.sh"
)

trim() {
  local s="$1"
  s="$(echo "$s" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')"
  echo "$s"
}

corpus_has_entry() {
  local mode="$1"
  local entry="$2"
  grep -Fqx "${mode}|${entry}" "$CORPUS"
}

corpus_has_kd_entry() {
  local mode="$1"
  local entry="$2"
  grep -Fq "KNOWN_DIVERGENCE|${mode}|${entry}|" "$CORPUS"
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
    echo "FAIL(wave11-coverage-manifest-format) $line"
    failures=$((failures + 1))
    continue
  fi

  echo "$script" >>"$seen_file"
  processed=$((processed + 1))

  if [[ "$status" != "covered" && "$status" != "known_divergence" ]]; then
    echo "FAIL(wave11-coverage-status) $script status='$status'"
    failures=$((failures + 1))
    continue
  fi

  has_covered=0
  has_kd=0
  IFS=',' read -r -a evidence_items <<<"$evidence"
  if [[ "${#evidence_items[@]}" -eq 0 ]]; then
    echo "FAIL(wave11-coverage-evidence-empty) $script"
    failures=$((failures + 1))
    continue
  fi

  for item_raw in "${evidence_items[@]}"; do
    item="$(trim "$item_raw")"
    if [[ "$item" != *:* ]]; then
      echo "FAIL(wave11-coverage-evidence-format) $script item='$item'"
      failures=$((failures + 1))
      continue
    fi

    mode="${item%%:*}"
    entry="${item#*:}"
    mode="$(trim "$mode")"
    entry="$(trim "$entry")"

    if [[ "$mode" != "check" && "$mode" != "build" && "$mode" != "run" && "$mode" != "test" && "$mode" != "cli" ]]; then
      echo "FAIL(wave11-coverage-evidence-mode) $script mode='$mode'"
      failures=$((failures + 1))
      continue
    fi

    if [[ "$mode" != "cli" && ! -f "$entry" ]]; then
      echo "FAIL(wave11-coverage-evidence-missing-file) $script ${mode}:${entry}"
      failures=$((failures + 1))
      continue
    fi

    if corpus_has_kd_entry "$mode" "$entry"; then
      has_kd=1
      continue
    fi
    if corpus_has_entry "$mode" "$entry"; then
      has_covered=1
      continue
    fi

    echo "FAIL(wave11-coverage-evidence-missing-corpus-entry) $script ${mode}:${entry}"
    failures=$((failures + 1))
  done

  if [[ "$status" == "covered" && "$has_covered" -eq 0 ]]; then
    echo "FAIL(wave11-coverage-covered-without-covered-evidence) $script"
    failures=$((failures + 1))
  fi
  if [[ "$status" == "known_divergence" && "$has_kd" -eq 0 ]]; then
    echo "FAIL(wave11-coverage-kd-without-kd-evidence) $script"
    failures=$((failures + 1))
  fi
done <"$MANIFEST"

for req in "${required_scripts[@]}"; do
  if ! grep -Fqx "$req" "$seen_file"; then
    echo "FAIL(wave11-coverage-missing-required-script) $req"
    failures=$((failures + 1))
  fi
done

if [[ "$processed" -eq 0 ]]; then
  echo "FAIL(wave11-coverage-empty-manifest) $MANIFEST"
  exit 1
fi

if [[ "$failures" -ne 0 ]]; then
  echo "wave11 coverage verification: FAIL (processed=$processed failures=$failures)"
  exit 1
fi

echo "wave11 coverage verification: PASS (processed=$processed)"
