//! expect-check-fail: place receiver

// §15.3: next() mutates the iterator, so it needs a place receiver — the
// temporary returned by items.iter() in a direct chain is not one. Bind the
// iterator (`var iter = items.iter()`) to advance it.

type Inner {
    tags: List[i32],
}

fn main:
    var items: List[Inner] = List.new()
    items.push(Inner { tags: List.new() })
    items.iter().next().unwrap().tags.push(3)
