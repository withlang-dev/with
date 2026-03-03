#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

SELFHOST_BIN="./with-stage2"

echo "rebuilding self-host compiler for Wave 7 MIR unit tests..."
./scripts/rebuild_selfhost.sh stage2 >/dev/null

if [[ ! -x "$SELFHOST_BIN" ]]; then
  echo "error: missing self-host compiler: $SELFHOST_BIN"
  exit 1
fi

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=0

run_expect_pattern() {
  local name="$1"
  local src="$2"
  local pattern="$3"
  local out="$tmpdir/${name}.out"
  local err="$tmpdir/${name}.err"

  if ! "$SELFHOST_BIN" check "$src" --dump-mir >"$out" 2>"$err"; then
    echo "FAIL(wave7-unit-check) $name: $src"
    cat "$err"
    failures=$((failures + 1))
    return
  fi

  if ! grep -Eq "$pattern" "$out"; then
    echo "FAIL(wave7-unit-pattern) $name: $src pattern=$pattern"
    cat "$out"
    failures=$((failures + 1))
    return
  fi

  echo "PASS(wave7-unit) $name"
}

run_expect_no_pattern() {
  local name="$1"
  local src="$2"
  local pattern="$3"
  local out="$tmpdir/${name}.out"
  local err="$tmpdir/${name}.err"

  if ! "$SELFHOST_BIN" check "$src" --dump-mir >"$out" 2>"$err"; then
    echo "FAIL(wave7-unit-check) $name: $src"
    cat "$err"
    failures=$((failures + 1))
    return
  fi

  if grep -Eq "$pattern" "$out"; then
    echo "FAIL(wave7-unit-no-pattern) $name: $src unexpected_pattern=$pattern"
    cat "$out"
    failures=$((failures + 1))
    return
  fi

  echo "PASS(wave7-unit) $name"
}

run_determinism_check() {
  local name="$1"
  local src="$2"
  local out1="$tmpdir/${name}.det.1"
  local out2="$tmpdir/${name}.det.2"
  local err="$tmpdir/${name}.det.err"

  if ! "$SELFHOST_BIN" check "$src" --dump-mir >"$out1" 2>"$err"; then
    echo "FAIL(wave7-unit-determinism-run1) $name: $src"
    cat "$err"
    failures=$((failures + 1))
    return
  fi
  if ! "$SELFHOST_BIN" check "$src" --dump-mir >"$out2" 2>/dev/null; then
    echo "FAIL(wave7-unit-determinism-run2) $name: $src"
    failures=$((failures + 1))
    return
  fi
  if ! diff -u "$out1" "$out2" >/dev/null; then
    echo "FAIL(wave7-unit-determinism-diff) $name: $src"
    diff -u "$out1" "$out2" || true
    failures=$((failures + 1))
    return
  fi
  echo "PASS(wave7-unit-determinism) $name"
}

# MirBody construction primitives / CFG scaffolding.
run_expect_pattern "builder_blocks" "bootstrap/test/cases/assign.w" "^  bb0:"
run_expect_pattern "builder_terminator" "bootstrap/test/cases/assign.w" "goto -> bb|return;"
run_expect_pattern "builder_storage_live" "bootstrap/test/cases/assign.w" "StorageLive\\(_"

# Literals / arithmetic / field access.
run_expect_pattern "lower_literals" "bootstrap/test/cases/arithmetic_mixed.w" "const [0-9]+i32|const true|const false"
run_expect_pattern "lower_arithmetic" "bootstrap/test/cases/arithmetic_mixed.w" "binop\\(add|binop\\(sub|binop\\(mul|binop\\(div"
run_expect_pattern "lower_field_access" "bootstrap/test/cases/record_update.w" "copy _[0-9]+\\.f"

# Blocks / let / let-else.
run_expect_pattern "lower_block_let" "bootstrap/test/cases/assign.w" "StorageLive\\(_"
run_expect_pattern "lower_let_else_switch" "bootstrap/test/cases/let_else.w" "switchInt\\("

# Control flow.
run_expect_pattern "lower_if_else" "bootstrap/test/cases/if_simple.w" "switchInt\\("
run_expect_pattern "lower_loop_backedge" "bootstrap/test/cases/loop_simple.w" "goto -> bb"
run_expect_pattern "lower_while" "bootstrap/test/cases/while_cond.w" "switchInt\\("
run_expect_pattern "lower_for" "bootstrap/test/cases/for_loop.w" "discriminant\\(|switchInt\\("
run_expect_pattern "lower_break_continue" "bootstrap/test/cases/break_continue.w" "goto -> bb"
run_expect_pattern "lower_return" "bootstrap/test/cases/early_return.w" "return;"

# Pattern matching / decision trees.
run_expect_pattern "match_literal" "bootstrap/test/cases/match_int.w" "switchInt\\("
run_expect_pattern "match_enum_discriminant" "bootstrap/test/cases/match_or_enum.w" "discriminant\\("
run_expect_pattern "match_or_pattern" "bootstrap/test/cases/match_or_enum.w" "switchInt\\("
run_expect_pattern "match_guard" "bootstrap/test/cases/match_guard.w" "switchInt\\("

# Sugar lowering.
run_expect_pattern "sugar_optional_chain" "bootstrap/test/cases/opt_chain.w" "discriminant\\(|switchInt\\("
run_expect_pattern "sugar_default_operator" "bootstrap/test/cases/option_unwrap_or.w" "switchInt\\("
run_expect_pattern "sugar_with_form1" "bootstrap/test/cases/with_form1.w" "StorageLive\\(_"
run_expect_pattern "sugar_with_form2" "bootstrap/test/cases/with_builder.w" "StorageLive\\(_"
run_expect_pattern "sugar_with_form3" "bootstrap/test/cases/with_scoped.w" "StorageLive\\(_"
run_expect_pattern "sugar_record_update" "bootstrap/test/cases/record_update.w" "aggregate\\(kind="
run_expect_pattern "sugar_pipeline" "bootstrap/test/cases/pipeline.w" "call "
run_expect_pattern "sugar_let_else" "bootstrap/test/cases/let_else.w" "switchInt\\("
run_expect_pattern "sugar_closure" "bootstrap/test/cases/closure_capture.w" "const zst\\("

# Calls and dispatch.
run_expect_pattern "call_direct" "bootstrap/test/cases/calls.w" "call "
run_expect_pattern "call_method" "bootstrap/test/cases/by_value_method.w" "call "
run_expect_pattern "call_generic_mono" "bootstrap/test/cases/generic_multi.w" "call "

# Drop insertion.
run_expect_pattern "drop_scope_exit" "test/wave7/cases/drop_scope_exit.w" "drop\\("
run_expect_pattern "drop_early_return" "test/wave7/cases/drop_early_return.w" "drop\\("
run_expect_pattern "drop_break_continue" "test/wave7/cases/drop_break_continue.w" "drop\\("

# No sugar tokens should remain in MIR dump text.
run_expect_no_pattern "no_sugar_tokens" "bootstrap/test/cases/with_record_methods.w" "optional_chain|record_update|with_expr|let_else|pipeline"

# Determinism checks.
run_determinism_check "determinism_arithmetic" "bootstrap/test/cases/arithmetic_mixed.w"
run_determinism_check "determinism_match" "bootstrap/test/cases/match_or_enum.w"
run_determinism_check "determinism_with" "bootstrap/test/cases/with_form1.w"

if [[ "$failures" -ne 0 ]]; then
  echo "wave7 MIR unit tests: $failures failure(s)"
  exit 1
fi

echo "wave7 MIR unit tests: PASS"
