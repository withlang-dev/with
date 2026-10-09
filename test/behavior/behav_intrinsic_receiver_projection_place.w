type Inner {
    tags: List[i32],
}

type InnerList = List[Inner]

type Outer {
    items: List[Inner],
}

fn seed_items() -> List[Inner]:
    let items: List[Inner] = List.new()
    items.push(Inner { tags: List.new() })
    items

fn main:
    var items = seed_items()
    items[0].tags.push(11)
    assert(items[0].tags.len() == 1)
    assert(items[0].tags[0] == 11)

    var grouped = seed_items()
    grouped[0].tags.push(22)
    assert(grouped[0].tags.len() == 1)
    assert(grouped[0].tags[0] == 22)

    var alias_items: InnerList = seed_items()
    alias_items[0].tags.push(33)
    assert(alias_items[0].tags.len() == 1)
    assert(alias_items[0].tags[0] == 33)

    var outer = Outer { items: seed_items() }
    outer.items[0].tags.push(44)
    assert(outer.items[0].tags.len() == 1)
    assert(outer.items[0].tags[0] == 44)

    var ref_items = seed_items()
    ref_items[0].tags.push(55)
    assert(ref_items[0].tags.len() == 1)
    assert(ref_items[0].tags[0] == 55)

    var ref_alias_items: InnerList = seed_items()
    ref_alias_items[0].tags.push(66)
    assert(ref_alias_items[0].tags.len() == 1)
    assert(ref_alias_items[0].tags[0] == 66)

    var ref_outer = Outer { items: seed_items() }
    ref_outer.items[0].tags.push(77)
    assert(ref_outer.items[0].tags.len() == 1)
    assert(ref_outer.items[0].tags[0] == 77)
