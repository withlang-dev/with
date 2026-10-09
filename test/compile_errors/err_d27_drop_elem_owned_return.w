//! expect-error: return type mismatch

// D27 E1: a declared Thing return is an owned demand that cannot be satisfied
// by the `&Thing` element view (D22 §13.6).

type Thing { vals: List[i32] }

fn take_first(items: &List[Thing]) -> Thing: items[0]

fn main:
    var items: List[Thing] = List.new()
    items.push(Thing { vals: List.new() })
    let t = take_first(&items)
    assert(t.vals.len() == 0)
