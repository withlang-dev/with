//! expect-check-fail: cannot take ownership of a non-Copy field through a borrow (Vec[i32] is not Copy); borrow it, clone it, or restructure so the owner transfers it (D22 §13.6) — if arm

// #1395: through a read receiver the same arm is D22 §13.6's borrowed-field
// error. Before the fix it passed check and double-freed the Vec: the join
// byte-copied the field and both owners dropped it.
type S { p: Vec[i32] }
impl S:
    fn f(c: bool):
        let v = if c: self.p else: Vec.new()
        print(v.len())
fn main:
    var p: Vec[i32] = Vec.new()
    p.push(1)
    let s = S { p }
    s.f(true)
    print(s.p.len())
