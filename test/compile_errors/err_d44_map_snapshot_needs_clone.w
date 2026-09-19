//! expect-check-fail: HashMap.values() returns independent elements, so the element type must implement Clone

// D44 / §2.3: a snapshot owns independent elements, so a non-Copy element is
// cloned. A type that is neither Copy nor Clone cannot be snapshotted; the
// map can still be iterated, which observes.

use std.collections.HashMap

type Token { text: str }

fn main:
    var m: HashMap[i32, Token] = HashMap.new()
    m.insert(1, Token { text: "a".to_owned() })
    let ts = m.values()
