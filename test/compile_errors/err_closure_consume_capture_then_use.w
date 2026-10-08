//! expect-check-fail: use of moved value

// #1481 / §12.4: after a call that consumed the by-place capture, the
// binding itself is moved. A Vec, not a str: a str capture is copied (D111).
fn main:
    var c: Vec[i32] = [1]
    let f: fn() -> Vec[i32] = () => c
    let got = f()
    print(got.len())
    print(c.len())
