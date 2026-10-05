//! expect-error: argument retains access to `m` which is mutably captured by a closure in the same call (§15.7)

// docs/mut.md Rev 8 §15.8 — verifies the mechanism is *not* hardcoded to
// the method name "iter": HashMap.keys is also marked @[iter_of_self]
// (its std.collections declaration, D44).

use std.collections
fn use_keys(keys: MapKeys[i32, i32], cb: fn(i32) -> i32) -> i32:
    var sum = 0
    for k in keys:
        sum = sum + cb(k)
    sum

fn main:
    var m: HashMap[i32, i32] = HashMap.new()
    m.insert(1, 10)
    let n = use_keys(m.keys(), key => m.insert(key, key * 2))
    print("done")
