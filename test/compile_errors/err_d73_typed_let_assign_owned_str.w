//! expect-check-fail: cannot take ownership of a non-Copy value through a borrow (List[i32] is not Copy); borrow it, clone it
// §9.1 / D73 (#1479): `let t: List[i32] = (s = e)` demands an owned List of
// the view the assignment yields; write `(s = e).clone()` or bind the view.
// A List, not a str: a str local is read by copy (D111).
fn compute(n: i32) -> List[i32]: [n]
fn main:
    var s: List[i32] = List.new()
    let t: List[i32] = (s = compute(1))
    print(t.len())
