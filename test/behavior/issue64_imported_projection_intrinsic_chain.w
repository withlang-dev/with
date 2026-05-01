use issue64.types

fn main:
    var items = imported_list()
    items.get(0).tags.push(101)
    assert(items.get(0).tags.len() == 1)
    assert(items.get(0).tags.get(0) == 101)

    var ctx = imported_context()
    ctx.outer.items.get(0).tags.push(202)
    assert(ctx.outer.items.get(0).tags.len() == 1)
    assert(ctx.outer.items.get(0).tags.get(0) == 202)

    var binding_items = imported_list()
    let item = binding_items.get(0)
    item.tags.push(303)
    assert(item.tags.len() == 1)
    assert(item.tags.get(0) == 303)
    assert(item.label == "imported")
