//! expect-check-fail: shadowing is not allowed for 'x'

// §29.8: the initializer does not use the old binding, so the old `x`
// would still be live after the declaration.
fn main:
    let x = 1
    let x = 2
    print(f"{x}")
