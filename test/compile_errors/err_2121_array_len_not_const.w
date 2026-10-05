//! expect-error: `[T; N]`: the length is not a compile-time constant
// §4.3a (#2121): a `let` is a runtime value, so it is not an array length.
fn main:
    let n = 3
    let xs: [i32; n] = [0, 0, 0]
    print(xs.len())
