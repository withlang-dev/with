//! expect-check-fail: a field never moves out implicitly (§2.2, D32)

// #1395: a block's value is its tail; a bound block value is owned, so a
// field tail moves out of its owner.
type Tok { id: i32 }
impl Drop for Tok:
    move fn drop(): {}
type S { p: List[Tok] }
fn g():
    var s = S { p: List.new() }
    let v = { let _n = 1
              s.p }
    print(v.len())
    print(s.p.len())
fn main:
    g()
