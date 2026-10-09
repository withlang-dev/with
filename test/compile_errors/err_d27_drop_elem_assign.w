//! expect-error: type mismatch in assignment

// D27 E3: assignment to an owned Thing place cannot consume an element view.

type Thing { vals: List[i32] }

fn main:
    var items: List[Thing] = List.new()
    items.push(Thing { vals: List.new() })
    var slot = Thing { vals: List.new() }
    slot = items[0]
    assert(slot.vals.len() == 0)
