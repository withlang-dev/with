#!/usr/bin/env bash
set -euo pipefail

if [[ "$#" -lt 2 ]]; then
  echo "usage: $0 <manifest> <corpus> [required_script ...]"
  exit 2
fi

MANIFEST="$1"
CORPUS="$2"
shift 2
required_scripts=("$@")

if [[ ! -f "$MANIFEST" ]]; then
  echo "error: missing coverage manifest: $MANIFEST"
  exit 1
fi
if [[ ! -f "$CORPUS" ]]; then
  echo "error: missing corpus: $CORPUS"
  exit 1
fi

trim() {
  local s="$1"
  s="$(echo "$s" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')"
  echo "$s"
}

corpus_has_entry() {
  local path="$1"
  grep -Fqx "$path" "$CORPUS"
}

corpus_has_kd_entry() {
  local path="$1"
  grep -Fq "KNOWN_DIVERGENCE|${path}|" "$CORPUS"
}

seen_file="$(mktemp)"
trap 'rm -f "$seen_file"' EXIT
failures=0
processed=0

while IFS= read -r raw_line; do
  line="$(trim "$raw_line")"
  [[ -z "$line" ]] && continue
  [[ "${line:0:1}" == "#" ]] && continue

  IFS='|' read -r script status evidence note <<< "$line"
  script="$(trim "$script")"
  status="$(trim "$status")"
  evidence="$(trim "$evidence")"

  if [[ -z "$script" || -z "$status" || -z "$evidence" ]]; then
    echo "FAIL(simple-coverage-manifest-format) $line"
    failures=$((failures + 1))
    continue
  fi

  echo "$script" >> "$seen_file"
  processed=$((processed + 1))

  if [[ "$status" != "covered" && "$status" != "known_divergence" ]]; then
    echo "FAIL(simple-coverage-status) $script status='$status'"
    failures=$((failures + 1))
    continue
  fi

  has_covered=0
  has_kd=0
  IFS=',' read -r -a evidence_items <<< "$evidence"
  if [[ "${#evidence_items[@]}" -eq 0 ]]; then
    echo "FAIL(simple-coverage-evidence-empty) $script"
    failures=$((failures + 1))
    continue
  fi

  for item_raw in "${evidence_items[@]}"; do
    path="$(trim "$item_raw")"
    if [[ -z "$path" ]]; then
      echo "FAIL(simple-coverage-evidence-empty-item) $script"
      failures=$((failures + 1))
      continue
    fi
    if [[ ! -f "$path" ]]; then
      echo "FAIL(simple-coverage-evidence-missing-file) $script $path"
      failures=$((failures + 1))
      continue
    fi

    if corpus_has_kd_entry "$path"; then
      has_kd=1
      continue
    fi
    if corpus_has_entry "$path"; then
      has_covered=1
      continue
    fi

    echo "FAIL(simple-coverage-evidence-missing-corpus-entry) $script $path"
    failures=$((failures + 1))
  done

  if [[ "$status" == "covered" && "$has_covered" -eq 0 ]]; then
    echo "FAIL(simple-coverage-covered-without-covered-evidence) $script"
    failures=$((failures + 1))
  fi
  if [[ "$status" == "known_divergence" && "$has_kd" -eq 0 ]]; then
    echo "FAIL(simple-coverage-kd-without-kd-evidence) $script"
    failures=$((failures + 1))
  fi
done < "$MANIFEST"

for req in "${required_scripts[@]}"; do
  if ! grep -Fqx "$req" "$seen_file"; then
    echo "FAIL(simple-coverage-missing-required-script) $req"
    failures=$((failures + 1))
  fi
done

if [[ "$processed" -eq 0 ]]; then
  echo "FAIL(simple-coverage-empty-manifest) $MANIFEST"
  exit 1
fi

if [[ "$failures" -ne 0 ]]; then
  echo "simple coverage verification: FAIL (manifest=$MANIFEST processed=$processed failures=$failures)"
  exit 1
fi

echo "simple coverage verification: PASS (manifest=$MANIFEST processed=$processed)"
