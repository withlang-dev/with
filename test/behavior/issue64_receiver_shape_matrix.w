type Inner {
    tags: Vec[i32],
    label: str,
}

type InnerList = Vec[Inner]

type Outer {
    items: Vec[Inner],
}

type Context {
    outer: Outer,
}

fn make_inner(label: str) -> Inner:
    Inner { tags: Vec.new(), label }

fn make_items() -> Vec[Inner]:
    let items: Vec[Inner] = Vec.new()
    items.push(make_inner("left"))
    items.push(make_inner("right"))
    items

fn make_context() -> Context:
    let items = make_items()
    Context { outer: Outer { items } }

fn main:
    var direct = make_items()
    direct.get(0).tags.push(11)
    assert(direct.get(0).tags.len() == 1)
    assert(direct.get(0).tags.get(0) == 11)

    var grouped = make_items()
    (grouped.get(0)).tags.push(22)
    assert(grouped.get(0).tags.len() == 1)
    assert(grouped.get(0).tags.get(0) == 22)

    var alias_items: InnerList = make_items()
    alias_items.get(0).tags.push(33)
    assert(alias_items.get(0).tags.len() == 1)
    assert(alias_items.get(0).tags.get(0) == 33)

    var ctx = make_context()
    ctx.outer.items.get(0).tags.push(44)
    assert(ctx.outer.items.get(0).tags.len() == 1)
    assert(ctx.outer.items.get(0).tags.get(0) == 44)

    var helper_items = make_items()
    let item1 = helper_items.get(0)
    item1.tags.push(55)
    assert(item1.tags.len() == 1)
    assert(item1.tags.get(0) == 55)
    assert(item1.label == "left")

    var if_items = make_items()
    let item2 = if true: if_items.get(0) else: if_items.get(1)
    item2.tags.push(66)
    assert(item2.tags.len() == 1)
    assert(item2.tags.get(0) == 66)

    var match_items = make_items()
    let item3 = match 0:
        0 => match_items.get(0)
        _ => match_items.get(1)
    item3.tags.push(77)
    assert(item3.tags.len() == 1)
    assert(item3.tags.get(0) == 77)
