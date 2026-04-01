use issue64.types

fn imported_direct(items: &mut ImportedList):
    items.get(0).tags.push(101)

fn imported_nested(ctx: &mut ImportedContext):
    ctx.outer.items.get(0).tags.push(202)

fn imported_binding(items: &mut ImportedList):
    let item = items.get(0)
    item.tags.push(303)
    assert(item.tags.len() == 1)
    assert(item.tags.get(0) == 303)
    assert(item.label == "imported")

fn main:
    var items = imported_list()
    imported_direct(&mut items)
    assert(items.get(0).tags.len() == 1)
    assert(items.get(0).tags.get(0) == 101)

    var ctx = imported_context()
    imported_nested(&mut ctx)
    assert(ctx.outer.items.get(0).tags.len() == 1)
    assert(ctx.outer.items.get(0).tags.get(0) == 202)

    var binding_items = imported_list()
    imported_binding(&mut binding_items)
