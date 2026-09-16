//! expect-error: cos() takes a floating-point argument (f32 or f64)

// §17.6a / D42: math builtins take f32 or f64, never an integer.
fn main:
    let bad = cos(3)
    print(f"{bad}")
