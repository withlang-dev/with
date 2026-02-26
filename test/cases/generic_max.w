// Test generic function with multiple call sites
fn max(a: i32, b: i32) -> i32:
    if a > b: a else b

fn min(a: i32, b: i32) -> i32:
    if a < b: a else b

fn clamp(val: i32, lo: i32, hi: i32) -> i32:
    max(lo, min(val, hi))

fn main -> i32:
    println(max(3, 7))
    println(min(3, 7))
    println(clamp(5, 0, 10))
    println(clamp(-5, 0, 10))
    println(clamp(15, 0, 10))
