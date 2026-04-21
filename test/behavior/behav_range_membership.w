//! expect-stdout: ok

fn test_range_literal_membership:
    assert(1 in 1..=1000)
    assert(500 in 1..=1000)
    assert(1000 in 1..=1000)
    assert(0 not in 1..=1000)
    assert(1001 not in 1..=1000)

fn test_exclusive_range_membership:
    assert(1 in 1..3)
    assert(2 in 1..3)
    assert(3 not in 1..3)

fn test_range_value_membership:
    let inclusive = 10..=12
    assert(10 in inclusive)
    assert(12 in inclusive)
    assert(13 not in inclusive)

    let exclusive = 10..12
    assert(10 in exclusive)
    assert(11 in exclusive)
    assert(12 not in exclusive)

fn main:
    test_range_literal_membership()
    test_exclusive_range_membership()
    test_range_value_membership()
    print("ok")
