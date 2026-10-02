// D27 respell (#740): mutations through the `[i]` element place across an
// imported-type projection chain; `get` chains observe.

use issue64.types

fn main:
    var items = imported_list()
    items[0].tags.push(101)
    assert(items[0].tags.len() == 1)
    assert(items[0].tags[0] == 101)

    var ctx = imported_context()
    ctx.outer.items[0].tags.push(202)
    assert(ctx.outer.items[0].tags.len() == 1)
    assert(ctx.outer.items[0].tags[0] == 202)

    var binding_items = imported_list()
    binding_items[0].tags.push(303)
    let item = binding_items[0]
    assert(item.tags.len() == 1)
    assert(item.tags[0] == 303)
    assert(item.label == "imported")
