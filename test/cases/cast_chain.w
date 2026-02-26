// Test: chained type casts (i32 as f64 comparisons)
fn main -> i32:
    // i32 -> i64 -> i32
    let a: i32 = 42
    let b = a as i64
    let c = b as i32
    assert(c == 42)

    // i32 -> f64 -> i32
    let d: i32 = 21
    let e = d as f64
    let f = e as i32
    assert(f == 21)
    assert(f * 2 == 42)

    // f64 arithmetic then cast
    let g = 10.5
    let h = 4.0
    let i = g * h
    assert(i as i32 == 42)

    // Small types
    let j: i32 = 200
    let k = j as i64
    assert(k as i32 == 200)

