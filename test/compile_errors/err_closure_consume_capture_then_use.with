//! expect-check-fail: use of moved value

// #1481 / §12.4: after a call that consumed the by-place capture, the
// binding itself is moved. A List, not a str: a str capture is copied (D111).
type Tok { id: i32 }
impl Drop for Tok:
    move fn drop(): {}
fn main:
    var c: List[Tok] = [Tok { id: 1 }]
    let f: fn() -> List[Tok] = () => c
    let got = f()
    print(got.len())
    print(c.len())
