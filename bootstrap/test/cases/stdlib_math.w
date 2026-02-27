// Test: stdlib math functions
use std.math

fn main -> i32:
    // Integer math
    assert(abs(0 - 42) == 42)
    assert(abs(42) == 42)
    assert(min(3, 7) == 3)
    assert(max(3, 7) == 7)
    assert(clamp(50, 0, 100) == 50)
    assert(clamp(0 - 10, 0, 100) == 0)
    assert(clamp(200, 0, 100) == 100)

    // Float math
    let sq = sqrt_f64(9.0)
    assert(sq > 2.99)
    assert(sq < 3.01)

    let p = pow_f64(2.0, 10.0)
    assert(p > 1023.0)
    assert(p < 1025.0)

    assert(floor_f64(3.7) > 2.99)
    assert(floor_f64(3.7) < 3.01)

    assert(ceil_f64(3.2) > 3.99)
    assert(ceil_f64(3.2) < 4.01)

    // Trig
    let s = sin_f64(0.0)
    assert(s > -0.01)
    assert(s < 0.01)

    let c = cos_f64(0.0)
    assert(c > 0.99)
    assert(c < 1.01)

    // Constants
    assert(PI > 3.14)
    assert(PI < 3.15)
    assert(E > 2.71)
    assert(E < 2.72)

    println("all stdlib math tests passed")
