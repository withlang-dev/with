fn abs(x: i32) -> i32 =
    if x < 0 then -x else x

fn main() -> i32 =
    assert(abs(-42) == 42)
    0
