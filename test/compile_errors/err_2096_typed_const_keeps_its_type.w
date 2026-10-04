//! expect-error: implicit float narrowing from `f64` to `f32`

// D88 (§4.2.1): a `const` with a declared type, or whose initializer has a
// suffixed literal, has that type at every use.

const WIDE: f64 = 12.0

fn main:
    let z: f32 = WIDE
    print(f"{z}")
