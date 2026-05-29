// Spec test: Section 4.2.7 — Chained Comparisons.

var CHAIN_COMPARE_COUNT = 0

fn chain_compare_middle -> i32:
    CHAIN_COMPARE_COUNT = CHAIN_COMPARE_COUNT + 1
    5

fn test_ordered_comparisons_chain:
    let x = 5
    assert(0 < x < 10)
    assert(not (0 < x < 4))
    assert(5 <= x <= 5)

fn test_chained_comparison_evaluates_middle_once:
    CHAIN_COMPARE_COUNT = 0
    assert(0 < chain_compare_middle() < 10)
    assert(CHAIN_COMPARE_COUNT == 1)
