type Inner {
    tags: Vec[i32],
}

fn do_push(items: &mut Vec[Inner]):
    let item = items.get(0)
    item.tags.push(99)

fn main:
    var inners: Vec[Inner] = Vec.new()
    inners.push(Inner { tags: Vec.new() })
    do_push(&mut inners)
    assert(inners.get(0).tags.len() == 1)
    assert(inners.get(0).tags.get(0) == 99)
