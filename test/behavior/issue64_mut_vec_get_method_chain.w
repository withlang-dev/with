type Inner {
    tags: Vec[i32],
}

fn main:
    var inners: Vec[Inner] = Vec.new()
    inners.push(Inner { tags: Vec.new() })
    let item = inners.get(0)
    item.tags.push(99)
    assert(inners.get(0).tags.len() == 1)
    assert(inners.get(0).tags.get(0) == 99)
