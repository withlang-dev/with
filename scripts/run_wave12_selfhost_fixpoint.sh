#!/usr/bin/env bash
set -euo pipefail

# Wave 12: Self-host fixpoint validation.
#
# Validates that Stage2 (built by Stage1/bootstrap) and Stage3 (built by Stage2)
# produce structurally equivalent compilers.
#
# Validation levels:
#   Level 1: Full test suite (waves 1-11) passes with Stage2
#   Level 2: Stage2 IR == Stage3 IR for fixpoint corpus
#   Level 3: Binary comparison (optional, non-blocking)

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

source "${ROOT_DIR}/scripts/selfhost_runner.sh"
source "${ROOT_DIR}/scripts/parity_states.sh"

CORPUS_FILE="test/wave12/fixpoint_corpus.txt"
STAGE2_BIN="./out/bin/with-stage2"
STAGE3_BIN="./out/bin/with-stage3"

level1_status="SKIP"
level2_status="SKIP"
level3_status="SKIP"

# ─── Step 1: Build Stage1 → Stage2 → Stage3 ───

echo "=== wave12: building stage3 ==="
if ! bash scripts/rebuild_selfhost.sh stage3; then
  echo "FAIL(wave12-build) stage3 build failed"
  echo ""
  echo "validation-level-1: SKIP"
  echo "validation-level-2: SKIP"
  echo "validation-level-3: SKIP"
  echo "wave12 selfhost fixpoint: FAIL"
  exit 1
fi
echo ""

if [[ ! -x "$STAGE2_BIN" ]]; then
  echo "error: missing Stage2 binary: $STAGE2_BIN"
  exit 1
fi
if [[ ! -x "$STAGE3_BIN" ]]; then
  echo "error: missing Stage3 binary: $STAGE3_BIN"
  exit 1
fi
if [[ ! -f "$CORPUS_FILE" ]]; then
  echo "error: missing corpus file: $CORPUS_FILE"
  exit 1
fi

# ─── Step 2: Run full test suite with Stage2 ───

echo "=== wave12: running test suite (waves 1-11) ==="
if bash scripts/run_all_wave_tests.sh; then
  level1_status="PASS"
  echo "validation-level-1: PASS"
else
  level1_status="FAIL"
  echo "validation-level-1: FAIL"
  echo ""
  echo "validation-level-1: FAIL"
  echo "validation-level-2: SKIP"
  echo "validation-level-3: SKIP"
  echo "wave12 selfhost fixpoint: FAIL"
  exit 1
fi
echo ""

# ─── Step 3: IR fixpoint comparison (Stage2 vs Stage3) ───

echo "=== wave12: IR fixpoint comparison ==="

# Prepare runners for both stages
STAGE2_RUNNER="$(prepare_selfhost_runner "$ROOT_DIR" "$STAGE2_BIN")"
# Save first runner dir so we can clean it up
STAGE2_RUNNER_DIR="$SELFHOST_RUNNER_DIR"

# Prepare stage3 runner in a separate temp dir
STAGE3_RUNNER_DIR=""
mkdir -p "${ROOT_DIR}/out/tmp"
stage3_tmp="$(mktemp -d "${ROOT_DIR}/out/tmp/with-selfhost-runner.XXXXXX")"
if [[ -f "${ROOT_DIR}/out/lib/libwith_llvm_bridge.dylib" ]]; then
  mkdir -p "${stage3_tmp}/runtime"
  cp "$STAGE3_BIN" "${stage3_tmp}/with-stage2"
  chmod +x "${stage3_tmp}/with-stage2"
  cp "${ROOT_DIR}/out/lib/libwith_llvm_bridge.dylib" "${stage3_tmp}/runtime/libwith_llvm_bridge.dylib"
  STAGE3_RUNNER="${stage3_tmp}/with-stage2"
  STAGE3_RUNNER_DIR="$stage3_tmp"
else
  STAGE3_RUNNER="$STAGE3_BIN"
  rm -rf "$stage3_tmp"
fi

cleanup_runners() {
  if [[ -n "$STAGE2_RUNNER_DIR" && -d "$STAGE2_RUNNER_DIR" ]]; then
    rm -rf "$STAGE2_RUNNER_DIR"
  fi
  if [[ -n "$STAGE3_RUNNER_DIR" && -d "$STAGE3_RUNNER_DIR" ]]; then
    rm -rf "$STAGE3_RUNNER_DIR"
  fi
  cleanup_selfhost_runner
}
trap cleanup_runners EXIT

if bash scripts/compare_ir_structural.sh "$STAGE2_RUNNER" "$STAGE3_RUNNER" "$CORPUS_FILE"; then
  level2_status="PASS"
else
  level2_status="FAIL"
fi
echo ""

# ─── Step 4: Structured diagnostic comparison ───

echo "=== wave12: diagnostic comparison ==="
bash scripts/compare_structured_diagnostics.sh "$STAGE2_RUNNER" "$STAGE3_RUNNER" "$CORPUS_FILE" || true
echo ""

# ─── Step 5: Optional binary comparison ───

echo "=== wave12: binary comparison (optional) ==="
if bash scripts/compare_binaries_optional.sh "$STAGE2_BIN" "$STAGE3_BIN"; then
  # Check if it was PASS (identical) or INFO (divergent)
  level3_status="DEFERRED"
fi
echo ""

# ─── Summary ───

echo "=============================="
echo "wave12 selfhost fixpoint summary"
echo "=============================="
echo "validation-level-1: $level1_status (test suite)"
echo "validation-level-2: $level2_status (IR fixpoint)"
echo "validation-level-3: $level3_status (binary comparison)"
echo ""

if [[ "$level1_status" == "PASS" && "$level2_status" == "PASS" ]]; then
  echo "wave12 selfhost fixpoint: PASS"
  exit 0
else
  echo "wave12 selfhost fixpoint: FAIL"
  exit 1
fi
