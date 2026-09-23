//! expect-stdout: ok

// #1395: the two spellings the D32 error offers for a field in an owned
// join. `.clone()` keeps the owner whole; `move` vacates through a mutable
// path (a `var` base or a `mut fn` receiver) and leaves a valid empty value.
// A plain `let x = self.p` binds a view and moves nothing.
type S { p: str, v: Vec[i32] }
impl S:
    mut fn keep(c: bool) -> str:
        let path = if c: self.p.clone() else: ""
        path
    mut fn take(c: bool) -> str:
        let path = if c: move self.p else: ""
        path
    fn peek() -> i64:
        let view = self.v
        view.len()
fn main:
    var v: Vec[i32] = Vec.new()
    v.push(1)
    var s = S { p: "abc" ++ "", v }
    assert(s.keep(true) == "abc")
    assert(s.p == "abc")
    assert(s.peek() == 1)
    assert(s.take(true) == "abc")
    assert(s.p == "")
    var t = S { p: "xyz" ++ "", v: Vec.new() }
    let w = match t.p.len():
        0 => ""
        _ => move t.p
    assert(w == "xyz")
    t.p = "again" ++ ""
    assert(t.p == "again")
    print("ok")
