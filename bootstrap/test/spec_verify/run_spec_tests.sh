#!/usr/bin/env bash
set -uo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
WITH_BIN="$ROOT_DIR/zig-out/bin/with"
SPEC_DIR="$ROOT_DIR/test/spec_verify"

pass=0
fail=0
impl_gap=0

results=()

run_positive_test() {
    local name="$1"
    local file="$SPEC_DIR/${name}.w"
    local output
    output=$("$WITH_BIN" run "$file" 2>&1)
    local exit_code=$?
    if [ $exit_code -eq 0 ]; then
        results+=("PASS|$name|Compiled and ran successfully")
        pass=$((pass + 1))
    else
        results+=("IMPL_GAP|$name|Expected success, got exit $exit_code: $(echo "$output" | head -1)")
        impl_gap=$((impl_gap + 1))
    fi
}

run_negative_check_test() {
    local name="$1"
    local file="$SPEC_DIR/${name}.w"
    local output
    output=$("$WITH_BIN" check "$file" 2>&1)
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        results+=("PASS|$name|Correctly rejected: $(echo "$output" | head -1)")
        pass=$((pass + 1))
    else
        results+=("IMPL_GAP|$name|Expected rejection but check passed ('ok')")
        impl_gap=$((impl_gap + 1))
    fi
}

echo "=== With Compiler Spec Verification Tests ==="
echo ""

# --- Tier 1: Core Type System ---
echo "--- Tier 1: Core Type System ---"
run_positive_test "spec_implicit_widen_int"
run_positive_test "spec_unsigned_to_signed_widen_ok"
run_negative_check_test "spec_implicit_narrow_reject"
run_negative_check_test "spec_signed_to_unsigned_reject"
run_negative_check_test "spec_signed_to_unsigned_widen_reject"
run_negative_check_test "spec_unsigned_to_signed_reject"
run_negative_check_test "spec_int_to_float_reject"
run_negative_check_test "spec_float_narrow_reject"
run_positive_test "spec_float_widen_ok"
run_positive_test "spec_wrapping_ops"
run_positive_test "spec_implicit_default_return"

# --- Tier 2: Ownership & Borrowing ---
echo "--- Tier 2: Ownership & Borrowing ---"
run_negative_check_test "spec_partial_move_drop_reject"
run_positive_test "spec_record_update_nondrop_ok"
run_positive_test "spec_disjoint_borrow_nested"
run_negative_check_test "spec_same_field_borrow_reject"
run_negative_check_test "spec_ref_in_struct_reject"
run_positive_test "spec_nll_reborrow"
run_negative_check_test "spec_use_after_move_reject"
run_positive_test "spec_copy_survives"

# --- Tier 3: Advanced Features ---
echo "--- Tier 3: Advanced Features ---"
run_negative_check_test "spec_object_safety_byval_reject"
run_positive_test "spec_with_form2_builder"
run_positive_test "spec_with_form3_binding"
run_positive_test "spec_match_string"
run_positive_test "spec_trait_bounds"
run_positive_test "spec_operator_overload"
run_positive_test "spec_defer_lifo"
run_negative_check_test "spec_defer_no_return_reject"

# --- Tier 4: Concurrency & Metaprogramming ---
echo "--- Tier 4: Concurrency & Metaprogramming ---"
run_positive_test "spec_async_basic"
run_positive_test "spec_comptime_fn"
run_positive_test "spec_display_trait"
run_positive_test "spec_must_use"

echo ""
echo "================================================"
echo "=== SPEC VERIFICATION RESULTS ==="
echo "================================================"
echo ""
printf "%-8s %-42s %s\n" "STATUS" "TEST" "DETAILS"
printf "%-8s %-42s %s\n" "------" "----" "-------"

for r in "${results[@]}"; do
    IFS='|' read -r status name details <<< "$r"
    printf "%-8s %-42s %s\n" "$status" "$name" "$details"
done

echo ""
echo "================================================"
echo "PASS: $pass / ${#results[@]}"
echo "IMPL_GAP: $impl_gap / ${#results[@]}"
echo "================================================"

if [ $impl_gap -gt 0 ]; then
    echo ""
    echo "Implementation gaps found:"
    for r in "${results[@]}"; do
        IFS='|' read -r status name details <<< "$r"
        if [ "$status" = "IMPL_GAP" ]; then
            echo "  - $name: $details"
        fi
    done
fi
