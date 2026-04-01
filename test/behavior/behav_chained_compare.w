//! expect-stdout: ok

fn test_basic_chain:
    assert(1 < 2 < 3)
    assert(not (1 < 3 < 2))
    assert(1 <= 2 <= 3)
    assert(1 <= 1 <= 1)

fn test_variable_chain:
    let x = 5
    assert(0 < x < 10)
    assert(not (0 < x < 3))
    assert(0 <= x <= 10)

fn test_mixed_ops:
    let x = 5
    assert(0 < x <= 5)
    assert(0 <= x < 6)
    assert(not (0 < x < 5))

fn test_four_way:
    assert(1 < 2 < 3 < 4)
    assert(not (1 < 2 < 3 < 3))

fn main:
    test_basic_chain()
    test_variable_chain()
    test_mixed_ops()
    test_four_way()
    print("ok")
