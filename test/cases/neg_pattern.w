// Test negative number patterns in match

fn sign(n: i32) -> i32 =
    match n
        0 -> 0
        -1 -> -1
        1 -> 1
        _ -> n

fn main() -> i32 =
    assert(sign(0) == 0)
    assert(sign(1) == 1)
    assert(sign(-1) == -1)
    assert(sign(42) == 42)
    0
