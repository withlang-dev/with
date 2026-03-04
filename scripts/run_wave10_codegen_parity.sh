#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
source "${ROOT_DIR}/scripts/parity_states.sh"
source "${ROOT_DIR}/scripts/selfhost_runner.sh"

STAGE0_BIN="./bootstrap/zig-out/bin/with"
SELFHOST_BIN="./with-stage2"
CORPUS_FILE="test/wave10/codegen_corpus.txt"
VERIFY_COVERAGE_SCRIPT="scripts/verify_wave10_coverage.sh"
TIMEOUT_BIN="$(command -v timeout || true)"
RUN_TIMEOUT_SECS=25

build_toolchains() {
  echo "building bootstrap compiler for Wave 10 codegen parity..."
  (
    cd bootstrap
    zig build -Doptimize=Debug >/dev/null
  )

  echo "rebuilding self-host compiler for Wave 10 codegen parity..."
  ./scripts/rebuild_selfhost.sh stage2 >/dev/null
}

extract_first_nonempty_line() {
  local file="$1"
  tr -d '\r' <"$file" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//' | awk 'NF{print; exit}'
}

extract_primary_diagnostic() {
  local err_file="$1"
  local out_file="$2"
  local line=""

  line="$(grep -m1 '^error:' "$err_file" || true)"
  if [[ -z "$line" ]]; then
    line="$(grep -m1 '^warning:' "$err_file" || true)"
  fi
  if [[ -z "$line" ]]; then
    line="$(extract_first_nonempty_line "$err_file")"
  fi
  if [[ -z "$line" ]]; then
    line="$(extract_first_nonempty_line "$out_file")"
  fi
  echo "$line"
}

extract_primary_warning() {
  local err_file="$1"
  local out_file="$2"
  local line=""

  line="$(grep -m1 '^warning:' "$err_file" || true)"
  if [[ -z "$line" ]]; then
    line="$(grep -m1 '^warning:' "$out_file" || true)"
  fi
  echo "$line" | tr -d '\r' | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//'
}

diagnostic_class() {
  local line="$1"
  local lower
  lower="$(echo "$line" | tr '[:upper:]' '[:lower:]')"

  if [[ -z "$lower" ]]; then
    echo ""
    return
  fi

  if [[ "$lower" == *"expected expression"* ]]; then
    echo "parse_expected_expression"
    return
  fi
  if [[ "$lower" == *"enum variant shorthand does not match expected enum type"* ]]; then
    echo "type_mismatch"
    return
  fi
  if [[ "$lower" == *"type mismatch"* || "$lower" == *"wrong argument type"* ]]; then
    echo "type_mismatch"
    return
  fi
  if [[ "$lower" == *"unknown type"* || "$lower" == *"cannot infer a single type"* ]]; then
    echo "generic_type_error"
    return
  fi
  if [[ "$lower" == *"does not implement trait"* ]]; then
    echo "missing_trait_impl"
    return
  fi
  if [[ "$lower" == *"object-safe"* ]]; then
    echo "object_safety"
    return
  fi
  if [[ "$lower" == *"unsupported call"* ]]; then
    echo "unsupported_call"
    return
  fi
  if [[ "$lower" == *"cannot allocate unsized type"* || "$lower" == *"unsized type"* ]]; then
    echo "unsized_type"
    return
  fi
  if [[ "$lower" == *"code generation failed"* ]]; then
    echo "codegen_failed"
    return
  fi
  if [[ "$lower" == *"build failed"* ]]; then
    echo "build_failed"
    return
  fi
  if [[ "$lower" == *"linking failed"* ]]; then
    echo "link_failed"
    return
  fi

  echo "$lower"
}

cleanup_selfhost_artifacts() {
  local src="$1"
  if [[ "$src" != *.w ]]; then
    return
  fi
  local stem="${src%.w}"
  local bin_path="$stem"
  local obj_path="${stem}.o"

  if [[ -f "$bin_path" ]]; then
    unlink "$bin_path" || true
  fi
  if [[ -f "$obj_path" ]]; then
    unlink "$obj_path" || true
  fi
}

run_compiler_mode() {
  local bin="$1"
  local mode="$2"
  local src="$3"
  local out_file="$4"
  local err_file="$5"

  if [[ "$mode" == "run" && -n "$TIMEOUT_BIN" ]]; then
    "$TIMEOUT_BIN" -k 5 "$RUN_TIMEOUT_SECS" "$bin" "$mode" "$src" >"$out_file" 2>"$err_file"
    return $?
  fi

  "$bin" "$mode" "$src" >"$out_file" 2>"$err_file"
}

build_toolchains

if [[ ! -x "$STAGE0_BIN" ]]; then
  echo "error: missing Stage0 compiler: $STAGE0_BIN"
  exit 1
fi
if [[ ! -x "$SELFHOST_BIN" ]]; then
  echo "error: missing self-host compiler: $SELFHOST_BIN"
  exit 1
fi
if [[ ! -f "$CORPUS_FILE" ]]; then
  echo "error: missing corpus file: $CORPUS_FILE"
  exit 1
fi
if [[ ! -x "$VERIFY_COVERAGE_SCRIPT" ]]; then
  echo "error: missing Wave 10 coverage verifier: $VERIFY_COVERAGE_SCRIPT"
  exit 1
fi
if ! "$VERIFY_COVERAGE_SCRIPT"; then
  exit 1
fi
if ! parity_validate_known_divergences_mode "$CORPUS_FILE"; then
  exit 1
fi

SELFHOST_BIN="$(prepare_selfhost_runner "$ROOT_DIR" "$SELFHOST_BIN")"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"; cleanup_selfhost_runner' EXIT

failures=0
known_divergences=0
processed=0
declared_known_divergences="$(parity_mode_kd_count "$CORPUS_FILE")"
used_kd_file="$tmpdir/used_known_divergences.txt"
touch "$used_kd_file"

while IFS= read -r line; do
  [[ -z "$line" ]] && continue
  [[ "${line:0:1}" == "#" ]] && continue
  [[ "$line" == KNOWN_DIVERGENCE\|* ]] && continue

  if [[ "$line" != *"|"* ]]; then
    echo "FAIL(wave10-codegen-parity-entry-format) $line"
    failures=$((failures + 1))
    continue
  fi

  mode="${line%%|*}"
  src="${line#*|}"
  if [[ "$mode" != "check" && "$mode" != "ir" && "$mode" != "build" && "$mode" != "run" ]]; then
    echo "FAIL(wave10-codegen-parity-entry-mode) $line"
    failures=$((failures + 1))
    continue
  fi
  if [[ ! -f "$src" ]]; then
    echo "FAIL(wave10-codegen-parity-missing-source) ${mode}|${src}"
    failures=$((failures + 1))
    continue
  fi

  processed=$((processed + 1))
  key="${mode}__${src//\//__}"
  kd_line="$(parity_mode_kd_line_for_entry "$CORPUS_FILE" "$mode" "$src")"

  stage0_out="$tmpdir/${key}.stage0.out"
  stage0_err="$tmpdir/${key}.stage0.err"
  self_out_1="$tmpdir/${key}.selfhost.out.1"
  self_err_1="$tmpdir/${key}.selfhost.err.1"
  self_out_2="$tmpdir/${key}.selfhost.out.2"
  self_err_2="$tmpdir/${key}.selfhost.err.2"

  stage0_rc=0
  run_compiler_mode "$STAGE0_BIN" "$mode" "$src" "$stage0_out" "$stage0_err" || stage0_rc=$?

  self_rc_1=0
  run_compiler_mode "$SELFHOST_BIN" "$mode" "$src" "$self_out_1" "$self_err_1" || self_rc_1=$?
  cleanup_selfhost_artifacts "$src"

  self_rc_2=0
  run_compiler_mode "$SELFHOST_BIN" "$mode" "$src" "$self_out_2" "$self_err_2" || self_rc_2=$?
  cleanup_selfhost_artifacts "$src"

  if [[ "$self_rc_1" -ne "$self_rc_2" ]]; then
    echo "FAIL(wave10-codegen-parity-nondeterministic-selfhost-status) ${mode}|${src} rc1=$self_rc_1 rc2=$self_rc_2"
    failures=$((failures + 1))
    continue
  fi
  if ! diff -u "$self_out_1" "$self_out_2" >/dev/null; then
    echo "FAIL(wave10-codegen-parity-nondeterministic-selfhost-stdout) ${mode}|${src}"
    failures=$((failures + 1))
    continue
  fi
  if ! diff -u "$self_err_1" "$self_err_2" >/dev/null; then
    echo "FAIL(wave10-codegen-parity-nondeterministic-selfhost-stderr) ${mode}|${src}"
    failures=$((failures + 1))
    continue
  fi

  is_match=0
  stage0_diag=""
  self_diag=""
  stage0_diag_class=""
  self_diag_class=""

  if [[ "$mode" == "run" ]]; then
    if [[ "$stage0_rc" -eq "$self_rc_1" ]] && diff -u "$stage0_out" "$self_out_1" >/dev/null && diff -u "$stage0_err" "$self_err_1" >/dev/null; then
      is_match=1
    fi
  else
    if [[ "$stage0_rc" -eq "$self_rc_1" ]]; then
      if [[ "$stage0_rc" -eq 0 ]]; then
        if [[ "$mode" == "ir" ]]; then
          is_match=1
        else
          stage0_warn_class="$(diagnostic_class "$(extract_primary_warning "$stage0_err" "$stage0_out")")"
          self_warn_class="$(diagnostic_class "$(extract_primary_warning "$self_err_1" "$self_out_1")")"
          if [[ "$stage0_warn_class" == "$self_warn_class" ]]; then
            is_match=1
          fi
        fi
      else
        stage0_diag="$(extract_primary_diagnostic "$stage0_err" "$stage0_out")"
        self_diag="$(extract_primary_diagnostic "$self_err_1" "$self_out_1")"
        stage0_diag_class="$(diagnostic_class "$stage0_diag")"
        self_diag_class="$(diagnostic_class "$self_diag")"
        if [[ "$stage0_diag_class" == "$self_diag_class" ]]; then
          is_match=1
        fi
      fi
    fi
  fi

  if [[ "$is_match" -eq 1 ]]; then
    if [[ -n "$kd_line" ]]; then
      echo "FAIL(wave10-codegen-parity-stale-known-divergence) ${mode}|${src}"
      failures=$((failures + 1))
      continue
    fi
    echo "PASS(wave10-codegen-parity) ${mode}|${src}"
    continue
  fi

  if [[ -n "$kd_line" ]]; then
    IFS='|' read -r _ kd_mode kd_test kd_what kd_correct kd_why <<< "$kd_line"
    echo "KNOWN_DIVERGENCE(wave10-codegen-parity) ${kd_mode}|${kd_test} what='${kd_what}' correct='${kd_correct}' why='${kd_why}' stage0_rc=$stage0_rc selfhost_rc=$self_rc_1"
    echo "${kd_mode}|${kd_test}" >> "$used_kd_file"
    known_divergences=$((known_divergences + 1))
  else
    echo "FAIL(wave10-codegen-parity-diff) ${mode}|${src} stage0_rc=$stage0_rc selfhost_rc=$self_rc_1"
    if [[ "$mode" == "run" ]]; then
      echo "  stdout(stage0): $(extract_first_nonempty_line "$stage0_out")"
      echo "  stdout(selfhost): $(extract_first_nonempty_line "$self_out_1")"
      echo "  stderr(stage0): $(extract_primary_diagnostic "$stage0_err" "$stage0_out")"
      echo "  stderr(selfhost): $(extract_primary_diagnostic "$self_err_1" "$self_out_1")"
    else
      stage0_diag="$(extract_primary_diagnostic "$stage0_err" "$stage0_out")"
      self_diag="$(extract_primary_diagnostic "$self_err_1" "$self_out_1")"
      stage0_diag_class="$(diagnostic_class "$stage0_diag")"
      self_diag_class="$(diagnostic_class "$self_diag")"
      echo "  stage0_diag_class=$stage0_diag_class stage0='${stage0_diag}'"
      echo "  selfhost_diag_class=$self_diag_class selfhost='${self_diag}'"
    fi
    failures=$((failures + 1))
  fi
done < "$CORPUS_FILE"

if [[ "$processed" -eq 0 ]]; then
  echo "error: empty corpus: $CORPUS_FILE"
  exit 1
fi

used_known_divergences="$(sort -u "$used_kd_file" | sed '/^$/d' | wc -l | tr -d ' ')"
if [[ "$declared_known_divergences" -ne "$used_known_divergences" ]]; then
  echo "FAIL(wave10-codegen-parity-known-divergence-accounting) declared=$declared_known_divergences used=$used_known_divergences"
  failures=$((failures + 1))
fi

echo ""
echo "wave10 codegen parity: processed=$processed failures=$failures known_divergences=$known_divergences"

if [[ "$failures" -ne 0 ]]; then
  echo "wave10 codegen parity: FAIL"
  exit 1
fi

echo "wave10 codegen parity: PASS"
