fn main() -> i32 =
    let x: i32 = 10
    let f = |y| x + y
    assert(f(32) == 42)
    0
