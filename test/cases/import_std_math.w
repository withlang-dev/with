// Test: std.math import with extended functions
use std.math

fn main() -> i32 =
    // Test basic integer functions
    assert(abs(-5) == 5)
    assert(abs(3) == 3)
    assert(min(3, 7) == 3)
    assert(max(3, 7) == 7)
    assert(clamp(15, 0, 10) == 10)
    assert(clamp(-5, 0, 10) == 0)
    assert(clamp(5, 0, 10) == 5)

    // Test float functions
    let s = sqrt_f64(9.0)
    assert(s > 2.99)
    assert(s < 3.01)

    let p = pow_f64(2.0, 10.0)
    assert(p > 1023.0)
    assert(p < 1025.0)

    let fl = floor_f64(3.7)
    assert(fl > 2.99)
    assert(fl < 3.01)

    let ce = ceil_f64(3.2)
    assert(ce > 3.99)
    assert(ce < 4.01)

    0
