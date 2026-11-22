//! expect-check-fail: min/max operands must be the same type
// §17.6a: min/max require same-typed operands; a signed/unsigned mix must be an
// explicit `as` cast rather than an implicit sign change (#511).
fn main:
    let a: u32 = 5
    let b: i32 = 3
    let _ = a.min(b)
