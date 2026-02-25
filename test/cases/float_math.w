// Test: Float math builtins (abs, min, max, clamp) with f64
use std.math

fn main() -> i32 =
    // abs with float
    let a = abs(-3.5)
    assert(a > 3.4)
    assert(a < 3.6)

    // min with float
    let b = min(2.5, 7.1)
    assert(b > 2.4)
    assert(b < 2.6)

    // max with float
    let d = max(2.5, 7.1)
    assert(d > 7.0)
    assert(d < 7.2)

    // clamp with float
    let e = clamp(15.0, 0.0, 10.0)
    assert(e > 9.9)
    assert(e < 10.1)

    let f = clamp(-5.0, 0.0, 10.0)
    assert(f > -0.1)
    assert(f < 0.1)

    let g = clamp(5.0, 0.0, 10.0)
    assert(g > 4.9)
    assert(g < 5.1)

    0
