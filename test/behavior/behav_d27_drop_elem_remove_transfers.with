//! expect-exit: 0

// D27 E2: `remove(0)` transfers an owned Thing; the vec no longer owns it and
// the binding drops it exactly once.

type Thing { vals: List[i32] }

fn main:
    var items: List[Thing] = List.new()
    items.push(Thing { vals: List.new() })
    let t = items.remove(0)
    assert(t.vals.len() == 0)
    assert(items.len() == 0)
