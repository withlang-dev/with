//! expect-check-fail: cannot vacate a field through a read path

// D32 (§2.2): the receiver of a read `fn` is a read path. Before D32 this
// shape passed check and double-freed at runtime (the vacate never reached
// the caller's storage; both copies dropped).

type Holder { v: Vec[i32], n: i32 }

fn consume(v: Vec[i32]): assert(v.len() >= 0)

impl Holder:
    fn take_it(self: &Self): consume(move self.v)

fn main:
    var xs: Vec[i32] = Vec.new()
    xs.push(7)
    let h = Holder { v: xs, n: 1 }
    h.take_it()
