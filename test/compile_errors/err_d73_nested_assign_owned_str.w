//! expect-check-fail: cannot take ownership of a non-Copy value through a borrow (str is not Copy); borrow it, clone it
// §9.1 / D73 (#1479): `a = b = s` — the inner assignment yields a view of
// `b`, and storing it into `a` is an owned demand on a non-Copy view.
// (The base lowered the inner assignment's operand twice: `b` and `a` both
// owned one buffer, `a` read the blanked source.)
fn compute(s: &str): s.clone() ++ "!"
fn main:
    var a = "".clone()
    var b = "".clone()
    a = b = compute("x")
    print(a)
    print(b)
