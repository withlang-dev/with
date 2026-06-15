//! expect-stdout: ok
// Spec test: §4.3c BTree collection literal targets.

fn test_btreeset_literal:
    let set: BTreeSet[i32] = [3, 1, 2, 2]
    assert(set.len() == 3)
    let items = set.items()
    assert(items.get(0) == 1)
    assert(items.get(1) == 2)
    assert(items.get(2) == 3)

fn test_btreemap_literal:
    let map: BTreeMap[str, i32] = ["b": 2, "a": 1, "b": 5]
    assert(map.len() == 2)
    assert(map.get("a").unwrap() == 1)
    assert(map.get("b").unwrap() == 5)
    let keys = map.keys()
    assert(keys.get(0) == "a")
    assert(keys.get(1) == "b")

fn test_empty_btreemap_literal:
    let map: BTreeMap[str, i32] = [:]
    assert(map.is_empty())

fn main:
    test_btreeset_literal()
    test_btreemap_literal()
    test_empty_btreemap_literal()
    print("ok")
