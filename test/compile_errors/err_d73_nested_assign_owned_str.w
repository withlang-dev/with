//! expect-check-fail: cannot take ownership of a non-Copy value through a borrow (List[i32] is not Copy); borrow it, clone it
// §9.1 / D73 (#1479): `a = b = v` — the inner assignment yields a view of
// `b`, and storing it into `a` is an owned demand on a non-Copy view.
// (The base lowered the inner assignment's operand twice: `b` and `a` both
// owned one buffer, `a` read the blanked source.)
// A List, not a str: a str local is read by copy (D111).
fn compute(n: i32) -> List[i32]: [n]
fn main:
    var a: List[i32] = List.new()
    var b: List[i32] = List.new()
    a = b = compute(1)
    print(a.len())
    print(b.len())
