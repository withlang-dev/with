#!/usr/bin/env bash

# Shared helpers for parity harness state handling.
# Corpus format supports:
# - source path entries (one per line)
# - comments starting with '#'
# - KNOWN_DIVERGENCE metadata entries:
#   KNOWN_DIVERGENCE|<test>|<what_differs>|<correct_compiler>|<why>

parity_kd_count() {
  local corpus_file="$1"
  awk -F'|' '$1=="KNOWN_DIVERGENCE"{c++} END{print c+0}' "$corpus_file"
}

parity_kd_line_for_test() {
  local corpus_file="$1"
  local test_path="$2"
  awk -F'|' -v t="$test_path" '$1=="KNOWN_DIVERGENCE" && $2==t {print; exit}' "$corpus_file"
}

parity_validate_known_divergences() {
  local corpus_file="$1"
  local tmp_sources
  local tmp_kd
  local failures=0
  tmp_sources="$(mktemp)"
  tmp_kd="$(mktemp)"

  awk '
    /^[[:space:]]*$/ { next }
    /^[[:space:]]*#/ { next }
    /^KNOWN_DIVERGENCE\|/ { next }
    { print $0 }
  ' "$corpus_file" | sort -u > "$tmp_sources"

  awk -F'|' '$1=="KNOWN_DIVERGENCE"{print $0}' "$corpus_file" > "$tmp_kd"

  while IFS='|' read -r tag test_path what_differs correct_compiler why rest; do
    [[ -z "${tag:-}" ]] && continue

    if [[ -z "${test_path:-}" || -z "${what_differs:-}" || -z "${correct_compiler:-}" || -z "${why:-}" ]]; then
      echo "FAIL(parity-known-divergence-invalid) ${tag}|${test_path:-}|${what_differs:-}|${correct_compiler:-}|${why:-}"
      failures=$((failures + 1))
      continue
    fi

    if [[ -n "${rest:-}" ]]; then
      echo "FAIL(parity-known-divergence-too-many-fields) ${test_path}"
      failures=$((failures + 1))
    fi

    if [[ "${correct_compiler}" != "stage0" && "${correct_compiler}" != "selfhost" && "${correct_compiler}" != "neither" ]]; then
      echo "FAIL(parity-known-divergence-correct-compiler) ${test_path} correct=${correct_compiler}"
      failures=$((failures + 1))
    fi

    if ! grep -Fxq "$test_path" "$tmp_sources"; then
      echo "FAIL(parity-known-divergence-missing-test-entry) ${test_path}"
      failures=$((failures + 1))
    fi
  done < "$tmp_kd"

  local dup_tests
  dup_tests="$(cut -d'|' -f2 "$tmp_kd" | sed '/^$/d' | sort | uniq -d || true)"
  if [[ -n "$dup_tests" ]]; then
    while IFS= read -r dup; do
      [[ -z "$dup" ]] && continue
      echo "FAIL(parity-known-divergence-duplicate) ${dup}"
      failures=$((failures + 1))
    done <<< "$dup_tests"
  fi

  rm -f "$tmp_sources" "$tmp_kd"

  if [[ "$failures" -ne 0 ]]; then
    return 1
  fi
  return 0
}
