//! expect-check-fail: cannot vacate a field through a read path

// D32 (§2.2): a vacate is a write — the explicit `move place.field` needs a
// `var` base or a `mut fn` receiver; a `let` base is a read path.

type Holder { v: Vec[i32], n: i32 }

fn consume(v: Vec[i32]): assert(v.len() >= 0)

fn main:
    var xs: Vec[i32] = Vec.new()
    xs.push(7)
    let h = Holder { v: xs, n: 1 }
    consume(move h.v)
