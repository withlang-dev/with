//! expect-check-fail: a field never moves out implicitly (§2.2, D32)

// #1395: `??` with an owned default is an owned join; its Option operand is
// a field, so the payload would move out of it.
type Tok { id: i32 }
impl Drop for Tok:
    move fn drop(): {}
type S { o: Option[List[Tok]] }
fn g(c: bool):
    var s = S { o: Some(List.new()) }
    let v = s.o ?? List.new()
    print(v.len())
    print(s.o.is_some())
fn main:
    g(true)
