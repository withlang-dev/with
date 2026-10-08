//! expect-check-fail: cannot take ownership of a non-Copy value through a borrow (Vec[i32] is not Copy); borrow it, clone it
// §9.1 / D73 (#1479): `let t: Vec[i32] = (s = e)` demands an owned Vec of
// the view the assignment yields; write `(s = e).clone()` or bind the view.
// A Vec, not a str: a str local is read by copy (D111).
fn compute(n: i32) -> Vec[i32]: [n]
fn main:
    var s: Vec[i32] = Vec.new()
    let t: Vec[i32] = (s = compute(1))
    print(t.len())
