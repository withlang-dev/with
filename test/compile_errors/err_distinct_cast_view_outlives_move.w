//! expect-check-fail: may outlive its origin

// §4.5 (D75, #1802): `n as &str` borrows `n`, exactly as `&n` does, so `n`
// cannot move out (`n as str`) while the view is still used.
type Name = distinct str

fn main:
    let n = "abc".clone() as Name
    let v = n as &str
    let t = n as str
    print(v)
    print(t)
