//! expect-check-fail: cannot take ownership of a non-Copy value through a borrow (str is not Copy); borrow it, clone it
// §9.1 / D73 (#1479): `let t: str = (s = e)` demands an owned str of the
// view the assignment yields; write `(s = e).clone()` or bind the view.
fn compute(s: &str): s.clone() ++ "!"
fn main:
    var s = "".clone()
    let t: str = (s = compute("x"))
    print(t)
