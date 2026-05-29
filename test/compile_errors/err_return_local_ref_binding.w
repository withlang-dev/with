//! expect-check-fail: returned view may outlive its origin 'x'

fn bad() -> &i32:
    let x = 42
    let r = &x
    r
