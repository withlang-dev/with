type Inner {
    tags: Vec[i32],
}

type InnerList = Vec[Inner]

type Outer {
    items: Vec[Inner],
}

fn seed_items() -> Vec[Inner]:
    let items: Vec[Inner] = Vec.new()
    items.push(Inner { tags: Vec.new() })
    items

fn main:
    var items = seed_items()
    items.get(0).tags.push(11)
    assert(items.get(0).tags.len() == 1)
    assert(items.get(0).tags.get(0) == 11)

    var grouped = seed_items()
    (grouped.get(0)).tags.push(22)
    assert(grouped.get(0).tags.len() == 1)
    assert(grouped.get(0).tags.get(0) == 22)

    var alias_items: InnerList = seed_items()
    alias_items.get(0).tags.push(33)
    assert(alias_items.get(0).tags.len() == 1)
    assert(alias_items.get(0).tags.get(0) == 33)

    var outer = Outer { items: seed_items() }
    outer.items.get(0).tags.push(44)
    assert(outer.items.get(0).tags.len() == 1)
    assert(outer.items.get(0).tags.get(0) == 44)

    var ref_items = seed_items()
    ref_items.get(0).tags.push(55)
    assert(ref_items.get(0).tags.len() == 1)
    assert(ref_items.get(0).tags.get(0) == 55)

    var ref_alias_items: InnerList = seed_items()
    ref_alias_items.get(0).tags.push(66)
    assert(ref_alias_items.get(0).tags.len() == 1)
    assert(ref_alias_items.get(0).tags.get(0) == 66)

    var ref_outer = Outer { items: seed_items() }
    ref_outer.items.get(0).tags.push(77)
    assert(ref_outer.items.get(0).tags.len() == 1)
    assert(ref_outer.items.get(0).tags.get(0) == 77)
