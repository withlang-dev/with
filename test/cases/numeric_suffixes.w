// Test numeric literal suffixes: 100_i64, 3.14_f32, etc.

fn main -> i32:
    let a = 100_i64
    let b = 3.14_f64
    let c = 42_i32
    let d = 1_000_000
    if a == 100 and c == 42 and d == 1000000
        0
    else
        1
