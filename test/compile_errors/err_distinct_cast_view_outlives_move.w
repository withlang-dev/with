//! expect-check-fail: may outlive its origin

// §4.5 (D75, #1802): `n as &List[i32]` borrows `n`, exactly as `&n` does, so
// `n` cannot move out (`n as List[i32]`) while the view is still used. A
// distinct List, not a distinct str: a str is copied (D111).
type Items = distinct List[i32]

fn main:
    let v: List[i32] = [1, 2]
    let n = v as Items
    let w = n as &List[i32]
    let t = n as List[i32]
    print(w.len())
    print(t.len())
