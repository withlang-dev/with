//! expect-check-fail: a field never moves out implicitly

// D32 (§2.2): return positions demand an owned value — a bare non-Copy
// field behind `return` is an implicit field move and errors at the site.

type Holder { v: Vec[i32], n: i32 }

fn take(h: Holder) -> Vec[i32]:
    return h.v

fn main:
    var xs: Vec[i32] = Vec.new()
    xs.push(7)
    let got = take(Holder { v: xs, n: 1 })
    assert(got.len() == 1)
