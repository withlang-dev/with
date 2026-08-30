//! expect-stdout: ok

// D32 (§2.2): the explicit `move place.field` through a `var` base vacates —
// reset-on-move leaves the field a valid empty value (§2.5.1) and the whole
// value stays transferable (the spelled-out move sanctions later whole uses).

type Holder { v: Vec[i32], n: i32 }

fn consume(v: Vec[i32]): assert(v.get(0) == 7)

fn main:
    var xs: Vec[i32] = Vec.new()
    xs.push(7)
    var h = Holder { v: xs, n: 1 }
    consume(move h.v)
    // Reading the vacated field is a use-after-move error by design; the
    // sibling stays readable, and reinitializing restores wholeness.
    assert(h.n == 1)
    h.v = Vec.new()
    assert(h.v.len() == 0)
    print("ok")
