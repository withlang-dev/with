//! expect-stdout: ok
// Spec test: §18.6 std.collections BTreeMap/BTreeSet surface.

use std.collections.BTreeMap
use std.collections.BTreeSet
fn test_btreemap_operations:
    var map: BTreeMap[str, i32] = BTreeMap[str, i32].new()
    assert(map.is_empty())
    map.insert("b", 2)
    map.insert("a", 1)
    map.insert("c", 3)
    map.insert("b", 20)
    assert(map.len() == 3)
    assert(map.get("a").unwrap() == 1)
    assert(map.get("b").unwrap() == 20)
    assert(map.get("z").is_none())

    let keys = map.keys()
    assert(keys[0] == "a")
    assert(keys[1] == "b")
    assert(keys[2] == "c")

    let values = map.values()
    assert(values[0] == 1)
    assert(values[1] == 20)
    assert(values[2] == 3)

    let items = map.items()
    let (k0, v0) = items[0]
    let (k1, v1) = items[1]
    let (k2, v2) = items[2]
    assert(k0 == "a" and v0 == 1)
    assert(k1 == "b" and v1 == 20)
    assert(k2 == "c" and v2 == 3)

    assert(map.remove("b").unwrap() == 20)
    assert(map.get("b").is_none())
    assert(map.len() == 2)
    map.clear()
    assert(map.is_empty())

fn test_btreeset_operations:
    var set: BTreeSet[i32] = BTreeSet[i32].new()
    assert(set.is_empty())
    set.insert(3)
    set.insert(1)
    set.insert(2)
    set.insert(2)
    assert(set.len() == 3)
    let items = set.items()
    assert(items[0] == 1)
    assert(items[1] == 2)
    assert(items[2] == 3)
    assert(set.remove(2))
    assert(not set.contains(2))
    assert(not set.remove(9))

    var other: BTreeSet[i32] = BTreeSet[i32].new()
    other.insert(3)
    other.insert(4)
    let unioned = set.union(&other)
    assert(unioned.len() == 3)
    assert(unioned.contains(1))
    assert(unioned.contains(3))
    assert(unioned.contains(4))
    let both = set.intersection(&other)
    assert(both.len() == 1)
    assert(both.contains(3))
    let left_only = set.difference(&other)
    assert(left_only.len() == 1)
    assert(left_only.contains(1))

fn main:
    test_btreemap_operations()
    test_btreeset_operations()
    print("ok")
