//! expect-error: an aggregate's elements do not convert

// §30.4 / D27 / #1354: an annotation demands what it says. A `(i32, i32)`
// value is not a `(i64, i64)` — no conversion reshapes a fixed aggregate —
// so this is a binding mismatch, not an invalid-MIR failure at codegen.

fn pair -> (i32, i32): (3, 4)

fn main:
    let (a, b): (i64, i64) = pair()
    print(f"{a} {b}")
