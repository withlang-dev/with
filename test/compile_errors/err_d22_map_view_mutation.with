//! expect-error: method 'List.push' requires a mutable receiver
// D22 §4.2: get borrows map-owned storage; §15.3: mutation requires an
// exclusive place, so the checker rejects mutation through the &V view.

use std.collections.HashMap
type Inner {
    tags: List[i32],
}

fn main:
    var lookup: HashMap[str, Inner] = HashMap.new()
    lookup.insert("alpha", Inner { tags: List.new() })
    lookup.get("alpha").unwrap().tags.push(4)
