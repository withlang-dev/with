//! expect-check-fail: a field never moves out implicitly (§2.2, D32)

// #1395: the match-arm form of the owned join — same rule as `if`.
type S { p: str }
impl S:
    mut fn f(c: bool):
        let path = match c:
            true => self.p
            false => ""
        print(path)
fn main:
    var s = S { p: "abc" }
    s.f(true)
    print(s.p)
