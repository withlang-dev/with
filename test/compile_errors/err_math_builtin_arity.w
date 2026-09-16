//! expect-error: cos() expects one floating-point argument

// §17.6a / D42: arity is fixed per builtin.
fn main:
    let bad = cos(1.0, 2.0)
    print(f"{bad}")
