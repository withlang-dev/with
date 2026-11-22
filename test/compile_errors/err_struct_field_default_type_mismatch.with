//! expect-check-fail: field default type mismatch for 'x'
// §4.3 (#632): a field default expression must match the field's declared type.
type P { x: i32 = "no" }

fn main:
    let _p = P { }
