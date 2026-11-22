//! expect-stdout: ok

// Test: prelude-provided trait impl Eq for i64.

fn main:
    let a: i64 = 42
    let b: i64 = 42
    let c: i64 = 7

    assert(a.eq(b))
    assert(not a.eq(c))

    print("ok")
