//! expect-debug-alloc: leak count=0

// HashMap.get exposes a shared view into map-owned storage. It must not copy a
// non-Copy value into a second owner. HashMap.remove is the ownership-transfer
// operation and returns the removed value exactly once.
use std.collections.HashMap
fn observe(map: &HashMap[i32, Vec[i64]]):
    let found: Option[&Vec[i64]] = map.get(1)
    assert(found.is_some())
    let values = found.unwrap()
    assert(values.len() == 2)
    assert(values[0] == 7)
    assert(values[1] == 9)

    let missing: Option[&Vec[i64]] = map.get(2)
    assert(missing.is_none())

fn main:
    var map: HashMap[i32, Vec[i64]] = HashMap.new()
    let values: Vec[i64] = Vec.new()
    values.push(7)
    values.push(9)
    map.insert(1, move values)

    observe(&map)

    let removed: Option[Vec[i64]] = map.remove(1)
    assert(removed.is_some())
    let owned = removed.unwrap()
    assert(owned.len() == 2)
    assert(map.remove(1).is_none())
