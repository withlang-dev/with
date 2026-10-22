//! expect-stdout: ok

// OrderedMap[K, V] over the STC sset (docs/proposals/stdlib_sourcing_plan.md
// Phase 3): ordered keys, insert returns the replaced value, get observes,
// remove transfers, in-order traversal, exactly-once drops of keys and
// values.

use std.collections.ordered_map.OrderedMap

type Tag { id: i32, slot: *mut i32 }
impl Drop for Tag:
    fn drop(move self: Self):
        unsafe:
            *self.slot = *self.slot + self.id

fn ints():
    var map = OrderedMap[i32, str].new()
    assert(map.is_empty() and map.first().is_none())
    assert(map.insert(5, "five").is_none())
    assert(map.insert(1, "one").is_none())
    assert(map.insert(9, "nine").is_none())
    assert(map.insert(5, "FIVE").unwrap() == "five")
    assert(map.len() == 3)
    assert(*map.get(&5).unwrap() == "FIVE" and map.get(&2).is_none())
    assert(map.contains(&1) and not map.contains(&4))
    let (fk, fv) = map.first().unwrap()
    assert(*fk == 1 and *fv == "one")
    let (lk, lv) = map.last().unwrap()
    assert(*lk == 9 and *lv == "nine")
    var cursor = map.iter()
    var keys: List[i32] = []
    while true:
        match cursor.next():
            Some((k, v)) => keys.push(*k)
            None => break
    assert(keys == [1, 5, 9])
    assert(map.remove(&5).unwrap() == "FIVE" and map.remove(&5).is_none())
    assert(map.len() == 2)

fn drops():
    var total: i32 = 0
    let slot = &raw mut total
    with 0 as scope:
        var map = OrderedMap[i32, Tag].new()
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
