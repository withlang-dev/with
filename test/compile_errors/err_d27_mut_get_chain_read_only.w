//! expect-error: requires a mutable receiver

// D27 E1: `items.get(0)` is a read-only view. Mutation uses the `[i]`
// IndexPlace spelling instead.

type Thing { vals: Vec[i32] }

fn main:
    var items: Vec[Thing] = Vec.new()
    items.push(Thing { vals: Vec.new() })
    items[0].vals.push(9)
    assert(items[0].vals.len() == 1)
