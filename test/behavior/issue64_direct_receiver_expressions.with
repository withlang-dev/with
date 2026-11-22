type Inner {
    tags: List[i32],
}

fn make_items() -> List[Inner]:
    let items: List[Inner] = List.new()
    items.push(Inner { tags: List.new() })
    items.push(Inner { tags: List.new() })
    items

fn main:
    var helper_items = make_items()
    helper_items[0].tags.push(11)

    var if_items = make_items()
    let branch_idx = if true: 0 else: 1
    if_items[branch_idx as i64].tags.push(22)

    var match_items = make_items()
    match_items[0].tags.push(33)

    var fresh_items = make_items()
    fresh_items[0].tags.push(44)
