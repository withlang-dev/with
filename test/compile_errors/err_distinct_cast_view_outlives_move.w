//! expect-check-fail: may outlive its origin

// §4.5 (D75, #1802): `n as &Vec[i32]` borrows `n`, exactly as `&n` does, so
// `n` cannot move out (`n as Vec[i32]`) while the view is still used. A
// distinct Vec, not a distinct str: a str is copied (D111).
type Items = distinct Vec[i32]

fn main:
    let v: Vec[i32] = [1, 2]
    let n = v as Items
    let w = n as &Vec[i32]
    let t = n as Vec[i32]
    print(w.len())
    print(t.len())
