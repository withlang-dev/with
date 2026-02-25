// Test: Match with wildcard patterns
fn classify(x: i32) -> i32 =
    match x
        0 -> 0
        1 -> 1
        _ -> 42

fn main() -> i32 =
    assert(classify(0) == 0)
    assert(classify(1) == 1)
    assert(classify(99) == 42)
    assert(classify(-5) == 42)
    0
