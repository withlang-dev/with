//! expect-error: requires a mutable receiver

// D27 E1: an element read through a borrowed collection is a read-only view.
// Mutation needs a mutable place: `items[0]` on a `var` or `mut` receiver.

type Thing { vals: List[i32] }

fn poke(items: &List[Thing]):
    items[0].vals.push(9)

fn main:
    var items: List[Thing] = List.new()
    items.push(Thing { vals: List.new() })
    poke(items)
    assert(items[0].vals.len() == 0)
