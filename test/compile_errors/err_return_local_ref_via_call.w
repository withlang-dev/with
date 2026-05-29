//! expect-check-fail: returned view may outlive its origin 'x'

fn same_ref(x: &i32) -> &i32:
    x

fn bad() -> &i32:
    let x = 42
    same_ref(&x)
