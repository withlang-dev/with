//! expect-check-fail: a field never moves out implicitly (§2.2, D32)

// #1395: a block's value is its tail; a bound block value is owned, so a
// field tail moves out of its owner.
type S { p: Vec[i32] }
fn g():
    var s = S { p: Vec.new() }
    let v = { let _n = 1
              s.p }
    print(v.len())
    print(s.p.len())
fn main:
    g()
