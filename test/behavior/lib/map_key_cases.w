// D110: a map observes its probe key (get, contains, remove, increment,
// decrement, update) and keeps its own copy of a key it inserts. D111: a str
// key is a value. So the caller's key reads its original text after every
// operation, and nothing leaks (run by behav_d111_map_keys.w under the debug
// allocator).
use std.collections.HashMap
use std.collections.HashSet

fn main:
    // An i64 key, used after increment, remove and insert.
    var counts: HashMap[i64, i64] = HashMap.new()
    let k: i64 = 7
    counts.increment(k)
    counts.increment(k)
    let removed = counts.remove(k) ?? 0
    counts.insert(k, removed + 40)
    assert((counts.get(k) ?? 0) == 42)
    assert(k == 7)

    // A str key, used after every operation.
    let key = f"k{1}"
    var m: HashMap[str, i64] = HashMap.new()
    m.insert(key, 1)
    assert(key == "k1")
    assert((m.get(key) ?? 0) == 1)
    assert(m.contains(key))
    m.increment(key)
    m.decrement(key)
    m.increment(key)
    assert((m.get(key) ?? 0) == 2)
    m.update(key, 0, (n) => n * 10)
    assert((m.get(key) ?? 0) == 20)
    assert((m.remove(key) ?? 0) == 20)
    m.increment(key)
    assert((m.get(key) ?? 0) == 1)
    assert(key == "k1")

    // A str element, used after every set operation.
    var s: HashSet[str] = HashSet.new()
    s.insert(key)
    assert(s.contains(key))
    assert(s.remove(key))
    assert(not s.contains(key))
    s.insert(key)
    assert(key == "k1")
    print("ok")
