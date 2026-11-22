//! expect-error: method 'HashMap.insert' requires a mutable receiver

use std.collections.HashMap
fn main:
    let lookup: HashMap[str, i32] = HashMap.new()
    let shared = &lookup
    shared.insert("a", 1)
