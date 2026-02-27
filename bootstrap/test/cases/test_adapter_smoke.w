use test.testing

fn main -> i32:
    assert_true(true)
    assert_true(1 + 1 == 2)
    assert_false(false)
    assert_eq_i32(42, 42)
    assert_eq_i32(1 + 2, 3)
    assert_ne_i32(1, 2)
    assert_lt_i32(1, 2)
    assert_gt_i32(3, 2)
    println("all assertions passed")
    0
