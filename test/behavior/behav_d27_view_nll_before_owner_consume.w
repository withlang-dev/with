//! expect-exit: 0

// D27/NLL: after a view's last use, consuming and replacing its owner is legal.
// #1099: function/closure cleanup must remove scope-depth metadata with
// each borrow row, or an earlier body's depth keeps this dead view live.

type Item { value: i32 }
type Owner { items: Vec[Item] }

fn identity(owner: Owner) -> Owner: owner

fn main:
    var owner = Owner { items: Vec.new() }
    owner.items.push(Item { value: 41 })
    let view = owner.items.get(0)
    assert(view.value == 41)
    owner = identity(owner)
    assert(owner.items.get(0).value == 41)
