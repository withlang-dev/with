//! expect-check-fail: a field never moves out implicitly (§2.2, D32)

// #1395: the match-arm form of the owned join — same rule as `if`.
// A List field, not a str: a str field read copies (D111).
type S { p: List[i32] }
impl S:
    mut fn f(c: bool):
        let path: List[i32] = match c:
            true => self.p
            false => List.new()
        print(path.len())
fn main:
    var s = S { p: [1, 2] }
    s.f(true)
    print(s.p.len())
