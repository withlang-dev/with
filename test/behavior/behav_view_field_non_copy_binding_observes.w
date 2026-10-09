//! expect-exit: 0

// D27 E3 retires #730's unannotated-let overbreadth: the binding aliases the
// field through the shared owner view and never acquires an owning drop.

type Outer { v: List[i32], n: i32 }

fn main:
    var o = Outer { v: List.new(), n: 7 }
    o.v.push(1)
    let observed = (&o).v
    assert(observed.len() == 1)
    assert(o.v.len() == 1)
