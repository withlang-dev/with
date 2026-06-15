//! expect-stdout: ok
// Spec test: §11.7 BTreeMap/BTreeSet membership through Contains syntax.

fn test_btreeset_contains:
    var set: BTreeSet[i32] = BTreeSet[i32].new()
    set.insert(3)
    set.insert(1)
    set.insert(2)
    set.insert(2)
    assert(set.len() == 3)
    assert(1 in set)
    assert(2 in set)
    assert(not (4 in set))
    assert(4 not in set)

fn test_btreemap_contains:
    var map: BTreeMap[str, i32] = BTreeMap[str, i32].new()
    map.insert("b", 2)
    map.insert("a", 1)
    map.insert("b", 4)
    assert(map.len() == 2)
    assert("a" in map)
    assert("b" in map)
    assert("missing" not in map)
    assert(map.get("b").unwrap() == 4)

fn main:
    test_btreeset_contains()
    test_btreemap_contains()
    print("ok")
