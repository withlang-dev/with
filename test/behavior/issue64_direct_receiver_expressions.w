type Inner {
    tags: Vec[i32],
}

fn make_items() -> Vec[Inner]:
    let items: Vec[Inner] = Vec.new()
    items.push(Inner { tags: Vec.new() })
    items.push(Inner { tags: Vec.new() })
    items

fn main:
    var helper_items = make_items()
    helper_items.get(0).tags.push(11)

    var if_items = make_items()
    (if true: if_items.get(0) else: if_items.get(1)).tags.push(22)

    var match_items = make_items()
    match_items.get(0).tags.push(33)

    make_items().get(0).tags.push(44)
