//! expect-check-fail: cannot mutate `s` while `t` is a live view into it
// §9.1 / D73 with §21.1 Rule 1 (#1479): `let t = (s = e)` binds a view of
// `s`; writing `s` while `t` is live is refused.
// A List, not a str: a str local is read by copy (D111).
fn compute(n: i32) -> List[i32]: [n]
fn main:
    var s: List[i32] = List.new()
    let t = (s = compute(1))
    s = compute(2)
    print(t.len())
