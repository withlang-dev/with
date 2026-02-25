// Test: closure used with early return pattern
fn find_positive(a: i32, b: i32, c: i32) -> i32 =
    let check = |x| x > 0
    if check(a) then return a
    if check(b) then return b
    if check(c) then return c
    0

fn main() -> i32 =
    let r1 = find_positive(-1, -2, 42)
    assert(r1 == 42)
    let r2 = find_positive(10, -2, -3)
    assert(r2 == 10)
    let r3 = find_positive(-1, 21, -3)
    assert(r3 == 21)
    0
