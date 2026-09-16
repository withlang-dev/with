//! expect-error: cos() takes a floating-point or integer argument

// §17.6a / D42: a math builtin takes f32, f64, or an integer (which
// converts to the call's float type); nothing else.
fn main:
    let bad = cos("x")
    print(f"{bad}")
