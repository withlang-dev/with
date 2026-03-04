#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
source "${ROOT_DIR}/scripts/selfhost_runner.sh"

SELFHOST_BIN="./with-stage2"

echo "rebuilding self-host compiler for Wave 6 sema unit tests..."
./scripts/rebuild_selfhost.sh stage2 >/dev/null

if [[ ! -x "$SELFHOST_BIN" ]]; then
  echo "error: missing self-host compiler: $SELFHOST_BIN"
  exit 1
fi

SELFHOST_BIN="$(prepare_selfhost_runner "$ROOT_DIR" "$SELFHOST_BIN")"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"; cleanup_selfhost_runner' EXIT

failures=0

# ── helpers ──────────────────────────────────────────────────────

# Run a file through --dump-typed and check that a pattern appears in output.
run_expect_pass_typed() {
  local name="$1"
  local src="$2"
  local expect_pat="$3"
  local out="$tmpdir/${name}.out"
  local err="$tmpdir/${name}.err"

  if ! "$SELFHOST_BIN" check "$src" --dump-typed >"$out" 2>"$err"; then
    echo "FAIL(wave6-unit-pass-check) $name: $src"
    cat "$err"
    failures=$((failures + 1))
    return
  fi

  if ! grep -q "$expect_pat" "$out"; then
    echo "FAIL(wave6-unit-pass-pattern) $name: $src  expected pattern: $expect_pat"
    cat "$out"
    failures=$((failures + 1))
    return
  fi

  echo "PASS(wave6-unit-pass) $name"
}

# Run a file through --dump-typed and check output is deterministic (two runs match).
run_determinism_check() {
  local name="$1"
  local src="$2"
  local out1="$tmpdir/${name}.det.1"
  local out2="$tmpdir/${name}.det.2"
  local err="$tmpdir/${name}.det.err"

  if ! "$SELFHOST_BIN" check "$src" --dump-typed >"$out1" 2>"$err"; then
    echo "FAIL(wave6-unit-determinism-run1) $name: $src"
    cat "$err"
    failures=$((failures + 1))
    return
  fi

  if ! "$SELFHOST_BIN" check "$src" --dump-typed >"$out2" 2>/dev/null; then
    echo "FAIL(wave6-unit-determinism-run2) $name: $src"
    failures=$((failures + 1))
    return
  fi

  if ! diff -u "$out1" "$out2" >/dev/null; then
    echo "FAIL(wave6-unit-determinism-diff) $name: $src"
    diff -u "$out1" "$out2" || true
    failures=$((failures + 1))
    return
  fi

  echo "PASS(wave6-unit-determinism) $name"
}

# Run a file through check and expect a non-zero exit with a pattern in stderr.
run_expect_fail() {
  local name="$1"
  local src="$2"
  local expect_err_pat="$3"
  local out="$tmpdir/${name}.out"
  local err="$tmpdir/${name}.err"

  if "$SELFHOST_BIN" check "$src" >"$out" 2>"$err"; then
    echo "FAIL(wave6-unit-fail-expected-error) $name: $src"
    cat "$out"
    failures=$((failures + 1))
    return
  fi

  if ! grep -q "$expect_err_pat" "$err"; then
    echo "FAIL(wave6-unit-fail-pattern) $name: $src  expected stderr pattern: $expect_err_pat"
    cat "$err"
    failures=$((failures + 1))
    return
  fi

  echo "PASS(wave6-unit-fail) $name"
}

# ── Declaration collection ────────────────────────────────────────

run_expect_pass_typed "decl_collection" \
  "test/wave6/cases/decl_collection_pass.w" \
  "fn make_point"

run_expect_pass_typed "decl_collection_trait" \
  "test/wave6/cases/decl_collection_pass.w" \
  "trait Describe"

run_expect_pass_typed "decl_collection_impl" \
  "test/wave6/cases/decl_collection_pass.w" \
  "impl Describe for Point"

run_expect_pass_typed "decl_collection_extern" \
  "test/wave6/cases/decl_collection_pass.w" \
  "extern fn int_to_string"

# ── Body checking and expression typing ──────────────────────────

run_expect_pass_typed "body_typing_let" \
  "test/wave6/cases/body_typing_pass.w" \
  "bind x: i32"

run_expect_pass_typed "body_typing_field_access" \
  "test/wave6/cases/body_typing_pass.w" \
  "field_access"

run_expect_pass_typed "body_typing_call" \
  "test/wave6/cases/body_typing_pass.w" \
  "call"

# ── Scope and binding semantics ──────────────────────────────────

run_expect_pass_typed "scope_binding_basic" \
  "test/wave6/cases/scope_binding_pass.w" \
  "bind a: i32"

run_expect_pass_typed "scope_binding_if" \
  "test/wave6/cases/scope_binding_pass.w" \
  "if_expr"

# ── Pattern bindings ─────────────────────────────────────────────

run_expect_pass_typed "pattern_enum_match" \
  "test/wave6/cases/pattern_binding_pass.w" \
  "match_expr"

run_expect_pass_typed "pattern_struct_field" \
  "test/wave6/cases/pattern_binding_pass.w" \
  "field_access"

# ── Method call resolution ───────────────────────────────────────

run_expect_pass_typed "method_call_new" \
  "test/wave6/cases/method_call_pass.w" \
  "fn Counter.new"

run_expect_pass_typed "method_call_increment" \
  "test/wave6/cases/method_call_pass.w" \
  "fn Counter.increment"

run_expect_pass_typed "method_call_get" \
  "test/wave6/cases/method_call_pass.w" \
  "fn Counter.get"

# ── Trait and impl declarations ──────────────────────────────────

run_expect_pass_typed "trait_impl_decl" \
  "test/wave6/cases/trait_impl_pass.w" \
  "trait Area"

run_expect_pass_typed "trait_impl_square" \
  "test/wave6/cases/trait_impl_pass.w" \
  "impl Area for Square"

run_expect_pass_typed "trait_impl_rect" \
  "test/wave6/cases/trait_impl_pass.w" \
  "impl Area for Rect"

# ── Copy trait knowledge ─────────────────────────────────────────

run_expect_pass_typed "copy_trait_i32" \
  "test/wave6/cases/copy_trait_pass.w" \
  "bind x: i32"

# ── Control flow typing ──────────────────────────────────────────

run_expect_pass_typed "control_while" \
  "test/wave6/cases/control_flow_pass.w" \
  "while_expr"

run_expect_pass_typed "control_return" \
  "test/wave6/cases/control_flow_pass.w" \
  "return_expr"

# ── Diagnostics — expected failures ──────────────────────────────

run_expect_fail "undefined_var" \
  "test/wave6/cases/undefined_var_error.w" \
  "undefined"

run_expect_fail "type_mismatch" \
  "test/wave6/cases/type_mismatch_error.w" \
  "type"

run_expect_fail "arity_mismatch" \
  "test/wave6/cases/arity_mismatch_error.w" \
  "arity\|argument"

# ── Wave 5 regression — must still pass ──────────────────────────

run_expect_pass_typed "wave5_regression_generic_return" \
  "test/wave5/cases/generic_return_infer.w" \
  "bind a: i32"

run_expect_pass_typed "wave5_regression_generic_bound" \
  "test/wave5/cases/generic_bound_pass.w" \
  "impl Show for Foo"

run_expect_fail "wave5_regression_duplicate_impl" \
  "test/wave5/cases/duplicate_impl_error.w" \
  "duplicate implementation"

run_expect_fail "wave5_regression_unknown_trait" \
  "test/wave5/cases/unknown_trait_error.w" \
  "unknown trait"

run_expect_fail "wave5_regression_generic_bound_error" \
  "test/wave5/cases/generic_bound_error.w" \
  "does not implement trait"

# ── Determinism checks ───────────────────────────────────────────

run_determinism_check "determinism_decl_collection" \
  "test/wave6/cases/decl_collection_pass.w"

run_determinism_check "determinism_body_typing" \
  "test/wave6/cases/body_typing_pass.w"

run_determinism_check "determinism_trait_impl" \
  "test/wave6/cases/trait_impl_pass.w"

# ── Summary ──────────────────────────────────────────────────────

if [[ "$failures" -ne 0 ]]; then
  echo "wave6 sema unit tests: $failures failure(s)"
  exit 1
fi

echo "wave6 sema unit tests: PASS"
