type Inner {
    tags: Vec[i32],
}

fn make_items() -> Vec[Inner]:
    let items: Vec[Inner] = Vec.new()
    items.push(Inner { tags: Vec.new() })
    items.push(Inner { tags: Vec.new() })
    items

fn pick_first(items: &mut Vec[Inner]) -> Inner:
    items.get(0)

fn pick_match(items: &mut Vec[Inner], idx: i32) -> Inner:
    match idx:
        0 => items.get(0)
        _ => items.get(1)

fn main:
    var helper_items = make_items()
    pick_first(&mut helper_items).tags.push(11)

    var if_items = make_items()
    (if true: if_items.get(0) else: if_items.get(1)).tags.push(22)

    var match_items = make_items()
    pick_match(&mut match_items, 0).tags.push(33)

    make_items().get(0).tags.push(44)
