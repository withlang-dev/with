//! expect-stdout: ok

fn main:
    // bool → i32: true=1, false=0 (zero-extend, not sign-extend)
    let t = true
    let f = false
    assert(t as i32 == 1)
    assert(f as i32 == 0)

    // bool → i64: same behavior
    assert(t as i64 == 1)
    assert(f as i64 == 0)

    // Comparison result → i32
    let x = 5
    let cmp = x > 3
    assert(cmp as i32 == 1)
    let cmp2 = x < 3
    assert(cmp2 as i32 == 0)

    print("ok")
