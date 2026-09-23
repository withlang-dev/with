//! expect-check-fail: use of moved value

// #1481 / §12.4: after a call that consumed the by-place capture, the
// binding itself is moved.
fn main:
    var c = "a".clone()
    let f: fn() -> str = () => c
    let got = f()
    print(got)
    print(c)
