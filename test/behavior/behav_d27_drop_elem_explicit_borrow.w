//! expect-exit: 0

// D27 E1: `&items[0]` explicitly spells the same view and does not add a
// second reference layer.

type Thing { vals: List[i32] }

fn main:
    var items: List[Thing] = List.new()
    items.push(Thing { vals: List.new() })
    let t = &items[0]
    assert(t.vals.len() == 0)
