fn find_negative(a: i32, b: i32, c: i32) -> i32:
    if a < 0: return a
    if b < 0: return b
    if c < 0: return c
    0

fn main -> i32:
    println(find_negative(1, -5, 3))
    println(find_negative(1, 2, -3))
    println(find_negative(1, 2, 3))
