//! expect-check-fail: comparison operands must have compatible types

fn test:
    let x = 42
    let r = &x
    let rr = &r
    let _ = rr == 42
