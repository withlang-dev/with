//! expect-error: a vector lane is a primitive integer or floating type

// §4.3d (D78, #1874): T is a primitive integer or floating type.
fn f(v: Vector[bool, 4]) -> i32: 0

fn main:
    print(f"{f(Vector[bool, 4](true, false, true, false))}")
