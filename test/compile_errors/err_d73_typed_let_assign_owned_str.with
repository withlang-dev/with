//! expect-check-fail: cannot take ownership of a non-Copy value through a borrow (List[Tok] is not Copy); borrow it, clone it
// §9.1 / D73 (#1479): `let t: List[Tok] = (s = e)` demands an owned List of
// the view the assignment yields; write `(s = e).clone()` or bind the view.
// A List, not a str: a str local is read by copy (D111).
type Tok { id: i32 }
impl Drop for Tok:
    move fn drop(): {}
fn compute(n: i32) -> List[Tok]: [n]
fn main:
    var s: List[Tok] = List.new()
    let t: List[Tok] = (s = compute(1))
    print(t.len())
