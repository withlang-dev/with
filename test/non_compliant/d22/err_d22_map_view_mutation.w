//! expect-check-fail: place receiver
//! NON-COMPLIANT: the checker does not yet reject mutation through the &V
//! view returned by map get (D22 §4.2: get borrows map-owned storage; §15.3
//! mutation requires an exclusive place). Stage 8 diagnostics work.

use std.collections.HashMap
type Inner {
    tags: List[i32],
}

fn main:
    var lookup: HashMap[str, Inner] = HashMap.new()
    lookup.insert("alpha", Inner { tags: List.new() })
    lookup.get("alpha").unwrap().tags.push(4)
