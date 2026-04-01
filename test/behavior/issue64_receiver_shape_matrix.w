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

fn pick_first(items: &mut Vec[Inner]) -> Inner:
    items.get(0)

fn pick_if(items: &mut Vec[Inner], cond: bool) -> Inner:
    if cond: items.get(0) else: items.get(1)

fn pick_match(items: &mut Vec[Inner], idx: i32) -> Inner:
    match idx
        0 => items.get(0)
        _ => items.get(1)

fn direct_chain(items: &mut Vec[Inner]):
    items.get(0).tags.push(11)

fn grouped_chain(items: &mut Vec[Inner]):
    (items.get(0)).tags.push(22)

fn alias_chain(items: &mut InnerList):
    items.get(0).tags.push(33)

fn nested_chain(ctx: &mut Context):
    ctx.outer.items.get(0).tags.push(44)

fn helper_binding(items: &mut Vec[Inner]):
    let item = pick_first(items)
    item.tags.push(55)
    assert(item.tags.len() == 1)
    assert(item.tags.get(0) == 55)
    assert(item.label == "left")

fn if_binding(items: &mut Vec[Inner]):
    let item = pick_if(items, true)
    item.tags.push(66)
    assert(item.tags.len() == 1)
    assert(item.tags.get(0) == 66)

fn match_binding(items: &mut Vec[Inner]):
    let item = pick_match(items, 0)
    item.tags.push(77)
    assert(item.tags.len() == 1)
    assert(item.tags.get(0) == 77)

fn main:
    var direct = make_items()
    direct_chain(&mut direct)
    assert(direct.get(0).tags.len() == 1)
    assert(direct.get(0).tags.get(0) == 11)

    var grouped = make_items()
    grouped_chain(&mut grouped)
    assert(grouped.get(0).tags.len() == 1)
    assert(grouped.get(0).tags.get(0) == 22)

    var alias_items: InnerList = make_items()
    alias_chain(&mut alias_items)
    assert(alias_items.get(0).tags.len() == 1)
    assert(alias_items.get(0).tags.get(0) == 33)

    var ctx = make_context()
    nested_chain(&mut ctx)
    assert(ctx.outer.items.get(0).tags.len() == 1)
    assert(ctx.outer.items.get(0).tags.get(0) == 44)

    var helper_items = make_items()
    helper_binding(&mut helper_items)

    var if_items = make_items()
    if_binding(&mut if_items)

    var match_items = make_items()
    match_binding(&mut match_items)
