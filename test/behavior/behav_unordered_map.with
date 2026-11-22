//! expect-stdout: ok

// UnorderedMap[K, V] over the STC hset (D149: the unordered hash map beside
// the insertion-ordered HashMap): insert returns the replaced value, get
// observes, remove transfers, traversal visits every entry once,
// exactly-once drops of keys and values.

use std.collections.unordered_map.UnorderedMap

type Tag { id: i32, slot: *mut i32 }
impl Drop for Tag:
    fn drop(move self: Self):
        unsafe:
            *self.slot = *self.slot + self.id

fn ints():
    var map = UnorderedMap[i32, str].new()
    assert(map.is_empty() and map.get(&1).is_none())
    assert(map.insert(5, "five").is_none())
    assert(map.insert(1, "one").is_none())
    assert(map.insert(9, "nine").is_none())
    assert(map.insert(5, "FIVE").unwrap() == "five")
    assert(map.len() == 3)
    assert(*map.get(&5).unwrap() == "FIVE" and map.get(&2).is_none())
    assert(map.contains(&1) and not map.contains(&4))
    var cursor = map.iter()
    var keys = 0
    var seen = 0
    while true:
        match cursor.next():
            Some((k, v)) =>
                keys = keys + *k
                seen = seen + 1
            None => break
    assert(seen == 3 and keys == 15)
    assert(map.remove(&5).unwrap() == "FIVE" and map.remove(&5).is_none())
    assert(map.len() == 2)
    var big = UnorderedMap[i32, i32].new()
    for i in 0..5000: assert(big.insert(i * 7919 % 5000, i).is_none())
    for i in 0..5000: assert(big.get(&i).is_some())
    for i in 0..2500: assert(big.remove(&i).is_some())
    assert(big.len() == 2500)

fn drops():
    var total: i32 = 0
    let slot = &raw mut total
    with 0 as scope:
        var map = UnorderedMap[i32, Tag].new()
        assert(map.insert(3, Tag { id: 30, slot: slot }).is_none())
        assert(map.insert(1, Tag { id: 10, slot: slot }).is_none())
        // The replaced value is returned and dropped here: 30.
        let replaced = map.insert(3, Tag { id: 31, slot: slot }).unwrap()
        drop(replaced)
        assert(total == 30)
        let taken = map.remove(&1).unwrap()
        drop(taken)
        assert(total == 40)
    // The one left dropped with the map: 31.
    assert(total == 71)

fn main:
    ints()
    drops()
    print("ok")
