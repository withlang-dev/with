//! expect-check-fail: a field never moves out implicitly (§2.2, D32)

// #1395: a `break` value becomes the loop's owned result.
type S { p: str }
fn g(c: bool):
    var s = S { p: "abc" }
    let x = loop:
        if c: break s.p
        break ""
    print(x)
    print(s.p)
fn main:
    g(true)
