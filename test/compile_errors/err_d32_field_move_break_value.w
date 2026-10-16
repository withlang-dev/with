//! expect-check-fail: a field never moves out implicitly (§2.2, D32)

// #1395: a `break` value becomes the loop's owned result.
// A List field, not a str: a str field read copies (D111).
type Tok { id: i32 }
impl Drop for Tok:
    move fn drop(): {}
type S { p: List[Tok] }
fn g(c: bool):
    var s = S { p: [Tok { id: 1 }, Tok { id: 2 }] }
    let x: List[Tok] = loop:
        if c: break s.p
        break List.new()
    print(x.len())
    print(s.p.len())
fn main:
    g(true)
