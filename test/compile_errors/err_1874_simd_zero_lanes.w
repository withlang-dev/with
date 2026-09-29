//! expect-error: a vector has at least one lane

// §4.3d (D78, #1874): N >= 1.
fn f(v: Vector[0, f32]) -> i32: 0

fn main:
    print("unreachable")
