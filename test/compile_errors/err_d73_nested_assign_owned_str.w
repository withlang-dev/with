//! expect-check-fail: cannot take ownership of a non-Copy value through a borrow (Vec[i32] is not Copy); borrow it, clone it
// §9.1 / D73 (#1479): `a = b = v` — the inner assignment yields a view of
// `b`, and storing it into `a` is an owned demand on a non-Copy view.
// (The base lowered the inner assignment's operand twice: `b` and `a` both
// owned one buffer, `a` read the blanked source.)
// A Vec, not a str: a str local is read by copy (D111).
fn compute(n: i32) -> Vec[i32]: [n]
fn main:
    var a: Vec[i32] = Vec.new()
    var b: Vec[i32] = Vec.new()
    a = b = compute(1)
    print(a.len())
    print(b.len())
