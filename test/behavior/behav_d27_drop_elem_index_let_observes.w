//! expect-exit: 0

// D27 E1/E2: `t` binds `&Thing`; the outer vec remains the sole owner and
// drops the allocation-bearing element exactly once.

type Thing { vals: Vec[i32] }

fn main:
    var vals: Vec[i32] = Vec.new()
    vals.push(7)
    var items: Vec[Thing] = Vec.new()
    items.push(Thing { vals: vals })
    let t = items[0]
    assert(t.vals.len() == 1)
    assert(t.vals[0] == 7)
    assert(items.len() == 1)
