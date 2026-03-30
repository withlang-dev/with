//! expect-stdout: ok

// Behavior test: for-loop basics (destructuring not yet supported)

fn test_basic_for:
    var sum = 0
    for i in 0..5:
        sum = sum + i
    assert(sum == 10)

fn test_for_inclusive:
    var sum = 0
    for i in 1..=5:
        sum = sum + i
    assert(sum == 15)

fn main:
    test_basic_for()
    test_for_inclusive()
    print("ok")
