//! expect-check-fail: cannot mutate `s` while `t` is a live view into it
// §9.1 / D73 with §21.1 Rule 1 (#1479): the view an assignment-arm join
// binds keeps `s` from being written while it is live.
// A List, not a str: a str local is read by copy (D111).
type Tok { id: i32 }
impl Drop for Tok:
    move fn drop(): {}
fn compute(n: i32) -> List[Tok]: [n]
fn main:
    var s: List[Tok] = List.new()
    let p = s.len() == 0
    let t = if p: s = compute(1) else: s = compute(2)
    s = compute(3)
    print(t.len())
