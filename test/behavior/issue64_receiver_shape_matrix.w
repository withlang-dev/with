// D27 respell (#740): element access observes; mutation goes through the
// `[i]` element place. The issue-64 receiver shapes are preserved — direct,
// grouped, alias-typedef, nested-context, helper-fn, if-else, and match
// bindings — with mutations spelled at the place and reads through views.

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
    direct[0].tags.push(11)
    assert(direct[0].tags.len() == 1)
    assert(direct[0].tags[0] == 11)

    var grouped = make_items()
    (grouped[0]).tags.push(22)
    assert(grouped[0].tags.len() == 1)
    assert(grouped[0].tags[0] == 22)

    var alias_items: InnerList = make_items()
    alias_items[0].tags.push(33)
    assert(alias_items[0].tags.len() == 1)
    assert(alias_items[0].tags[0] == 33)

    var ctx = make_context()
    ctx.outer.items[0].tags.push(44)
    assert(ctx.outer.items[0].tags.len() == 1)
    assert(ctx.outer.items[0].tags[0] == 44)

    var helper_items = make_items()
    helper_items[0].tags.push(55)
    let item1 = helper_items[0]
    assert(item1.tags.len() == 1)
    assert(item1.tags[0] == 55)
    assert(item1.label == "left")

    var if_items = make_items()
    if_items[0].tags.push(66)
    let item2 = if true: if_items[0] else: if_items[1]
    assert(item2.tags.len() == 1)
    assert(item2.tags[0] == 66)

    var match_items = make_items()
    match_items[0].tags.push(77)
    let item3 = match 0:
        0 => match_items[0]
        _ => match_items[1]
    assert(item3.tags.len() == 1)
    assert(item3.tags[0] == 77)
