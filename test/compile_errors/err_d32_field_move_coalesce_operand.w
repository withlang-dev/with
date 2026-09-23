//! expect-check-fail: a field never moves out implicitly (§2.2, D32)

// #1395: `??` with an owned default is an owned join; its Option operand is
// a field, so the payload would move out of it.
type S { o: Option[Vec[i32]] }
fn g(c: bool):
    var s = S { o: Some(Vec.new()) }
    let v = s.o ?? Vec.new()
    print(v.len())
    print(s.o.is_some())
fn main:
    g(true)
