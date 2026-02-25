// Test range patterns in match

fn classify(n: i32) -> i32 =
    match n
        0..=9 -> 1
        10..=99 -> 2
        100..=999 -> 3
        _ -> 4

fn main() -> i32 =
    assert(classify(5) == 1)
    assert(classify(42) == 2)
    assert(classify(500) == 3)
    assert(classify(1000) == 4)
    assert(classify(0) == 1)
    assert(classify(9) == 1)
    assert(classify(10) == 2)
    0
