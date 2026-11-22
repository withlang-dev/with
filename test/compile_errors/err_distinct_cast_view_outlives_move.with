//! expect-check-fail: may outlive its origin

// §4.5 (D75, #1802): `n as &List[Tok]` borrows `n`, exactly as `&n` does, so
// `n` cannot move out (`n as List[Tok]`) while the view is still used. A
// distinct List, not a distinct str: a str is copied (D111).
type Tok { id: i32 }
impl Drop for Tok:
    move fn drop(): {}
type Items = distinct List[Tok]

fn main:
    let v: List[Tok] = [Tok { id: 1 }, Tok { id: 2 }]
    let n = v as Items
    let w = n as &List[Tok]
    let t = n as List[Tok]
    print(w.len())
    print(t.len())
