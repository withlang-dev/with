//! expect-exit: 0

// D27 E1: `items[0]` is the element place; the receiver chain mutates it in
// place while the vec remains the sole owner.

type Thing { vals: List[i32] }

type Owner { items: List[Thing] }

impl Owner:
    mut fn push_into(value: i32): self.items[0].vals.push(value)

fn main:
    var items: List[Thing] = List.new()
    items.push(Thing { vals: List.new() })
    items[0].vals.push(9)
    assert(items[0].vals.len() == 1)
    assert(items[0].vals[0] == 9)

    var owner = Owner { items: List.new() }
    owner.items.push(Thing { vals: List.new() })
    owner.push_into(10)
    assert(owner.items[0].vals[0] == 10)
