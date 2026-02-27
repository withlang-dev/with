use test.testing
use test.runner

fn test_addition() -> void:
    assert_eq_i32(1 + 1, 2)

fn test_comparison() -> void:
    assert_true(3 > 2)
    assert_false(1 > 2)

fn main -> i32:
    begin()
    run_test("addition", test_addition)
    run_test("comparison", test_comparison)
    summary(2, 2)
