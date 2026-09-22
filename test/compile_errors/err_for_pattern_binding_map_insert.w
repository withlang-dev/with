//! expect-check-fail: is a live view

// #1317 / D44: `for (k, v) in m` is `m.iter()` and binds `&K`/`&V`; a
// pattern-bound loop view borrows the map exactly as the plain binding
// borrows a Vec, so inserting while iterating is rejected.

use std.collections

fn main:
    var m: HashMap[str, str] = HashMap.new()
    m.insert("a".clone(), "1".clone())
    for (k, v) in m:
        m.insert("b".clone(), "2".clone())
        print(k)
