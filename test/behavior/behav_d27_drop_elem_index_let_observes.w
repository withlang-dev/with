//! expect-exit: 0

// D27 E1/E2: `t` binds `&Thing`; the outer vec remains the sole owner and
// drops the allocation-bearing element exactly once.

type Thing { vals: List[i32] }

fn main:
    var vals: List[i32] = List.new()
    vals.push(7)
    var items: List[Thing] = List.new()
    items.push(Thing { vals: vals })
    let t = items[0]
    assert(t.vals.len() == 1)
    assert(t.vals[0] == 7)
    assert(items.len() == 1)
