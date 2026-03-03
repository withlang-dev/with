// Wave 6 unit test: Copy trait knowledge
// Covers: Copy types (i32, bool) used freely after binding

fn double(x: i32) -> i32:
    x + x

fn main -> i32:
    let x: i32 = 5
    let a = double(x)
    let b = double(x)    // x is Copy, can use twice
    a + b
