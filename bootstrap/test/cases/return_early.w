fn abs(x: i32) -> i32:
    if x < 0 then return 0 - x
    x

fn main -> i32:
    assert(abs(-42) == 42)
