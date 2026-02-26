fn abs(n: i32) -> i32:
    if n < 0: return -n
    n

fn clamp(n: i32, lo: i32, hi: i32) -> i32:
    if n < lo: return lo
    if n > hi: return hi
    n

fn main -> i32:
    println(abs(5))
    println(abs(-3))
    println(clamp(50, 0, 100))
    println(clamp(-10, 0, 100))
    println(clamp(200, 0, 100))
