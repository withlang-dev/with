// Test: nested match expressions
fn classify(x: i32, y: i32) -> i32 =
    match x
        0 -> match y
            0 -> 0
            _ -> 1
        1 -> match y
            0 -> 10
            1 -> 11
            _ -> 12
        _ -> 42

fn main() -> i32 =
    assert(classify(0, 0) == 0)
    assert(classify(0, 5) == 1)
    assert(classify(1, 0) == 10)
    assert(classify(1, 1) == 11)
    assert(classify(1, 99) == 12)
    assert(classify(99, 0) == 42)
    0
