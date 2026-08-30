//! expect-stdout: ok

// D32 (§2.2): the receiver of a `mut fn` is a mutable path — `move self.field`
// vacates the caller's storage in place.

type Holder { v: Vec[i32], n: i32 }

fn consume(v: Vec[i32]): assert(v.get(0) == 7)

impl Holder:
    mut fn take_it(): consume(move self.v)

fn main:
    var xs: Vec[i32] = Vec.new()
    xs.push(7)
    var h = Holder { v: xs, n: 1 }
    h.take_it()
    assert(h.v.len() == 0)
    assert(h.n == 1)
    print("ok")
