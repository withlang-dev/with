//! expect-exit: 0

// D27 E1/E2: `t` binds `&Thing`; the vec remains the sole element owner.

type Thing { vals: Vec[i32] }

fn main:
    var items: Vec[Thing] = Vec.new()
    items.push(Thing { vals: Vec.new() })
    let t = items[0]
    assert(t.vals.len() == 0)
    assert(items.len() == 1)
