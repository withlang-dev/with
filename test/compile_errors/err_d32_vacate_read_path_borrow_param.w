//! expect-check-fail: cannot vacate a field through a read path

// D32 (§2.2): an explicit `move` through a free `&T` borrow is a read path.
// Before D32 this shape passed check and double-freed at runtime.

type Holder { v: Vec[i32], n: i32 }

fn consume(v: Vec[i32]): assert(v.len() >= 0)

fn steal(h: &Holder): consume(move h.v)

fn main:
    var xs: Vec[i32] = Vec.new()
    xs.push(7)
    let h = Holder { v: xs, n: 1 }
    steal(&h)
