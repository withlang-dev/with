//! expect-error: cannot borrow mutably: already borrowed

// docs/mut.md Rev 8 §15.8 — verifies the mechanism is *not* hardcoded to
// the method name "iter": HashMap.keys is also marked @[iter_of_self]
// (built-in side, since the method has no user-source declaration).

fn use_keys(keys: Vec[i32], cb: fn(i32) -> i32) -> i32:
    var sum = 0
    for k in keys.iter():
        sum = sum + cb(k)
    sum

fn main:
    var m: HashMap[i32, i32] = HashMap.new()
    m.insert(1, 10)
    let n = use_keys(m.keys(), key => m.insert(key, key * 2))
    print("done")
