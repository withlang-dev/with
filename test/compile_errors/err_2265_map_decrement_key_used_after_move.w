//! expect-check-fail: use of moved value

// #2265: HashMap.decrement takes its key as an owned parameter and consumes it, so a
// later use of the binding is refused. The checker missed it and the
// program read the move-blanked string.
use std.collections.HashMap
use std.collections.HashSet

fn key(): f"k{1}"

fn main:
    var m: HashMap[str, i32] = HashMap.new()
    var s: HashSet[str] = HashSet.new()
    m.insert(key(), 1)
    s.insert(key())
    let a = key()
    m.decrement(a)
    print(a)
