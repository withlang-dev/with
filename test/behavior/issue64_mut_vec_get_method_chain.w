// D27 respell (#740): mutation goes through the `[i]` element place;
// `get` observes — the binding holds a view and reads stay legal.

type Inner {
    tags: List[i32],
}

fn main:
    var inners: List[Inner] = List.new()
    inners.push(Inner { tags: List.new() })
    inners[0].tags.push(99)
    let item = inners[0]
    assert(item.tags.len() == 1)
    assert(inners[0].tags[0] == 99)
