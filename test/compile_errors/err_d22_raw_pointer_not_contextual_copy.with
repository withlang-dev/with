//! expect-error: type mismatch in binding

// D22: contextual Copy materializes an independent `T` from a `&T` once an
// owned-value demand is established. A raw pointer is outside that rule:
// `raw` is `*const i32`, never `&i32`, so the typed binding is a type
// mismatch and no owned value is synthesized.

fn main:
    let value = 84
    let raw = &raw const value
    let snapshot: i32 = raw
