//! expect-check-fail: a field never moves out implicitly (§2.2, D32)

// #1395: a `break` value becomes the loop's owned result.
// A List field, not a str: a str field read copies (D111).
type S { p: List[i32] }
fn g(c: bool):
    var s = S { p: [1, 2] }
    let x: List[i32] = loop:
        if c: break s.p
        break List.new()
    print(x.len())
    print(s.p.len())
fn main:
    g(true)
