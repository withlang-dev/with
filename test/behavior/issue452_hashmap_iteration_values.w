//! expect-stdout: ok

fn test_hashmap_values:
    let empty: HashMap[str, i32] = HashMap.new()
    let empty_values = empty.values()
    assert(empty_values.len() == 0)

    var map: HashMap[str, i32] = HashMap.new()
    map.insert("alpha", 1)
    map.insert("beta", 2)
    map.insert("alpha", 3)

    let values = map.values()
    assert(values.len() == 2)
    assert(values.contains(2))
    assert(values.contains(3))

fn test_hashmap_items:
    var map: HashMap[str, i32] = HashMap.new()
    map.insert("alpha", 1)
    map.insert("beta", 2)
    map.insert("alpha", 3)

    let items = map.items()
    assert(items.len() == 2)

    var saw_alpha = false
    var saw_beta = false
    var total = 0
    for (key, value) in items:
        if key == "alpha":
            saw_alpha = true
            assert(value == 3)
        if key == "beta":
            saw_beta = true
            assert(value == 2)
        total = total + value
    assert(saw_alpha)
    assert(saw_beta)
    assert(total == 5)

fn test_hashmap_direct_iteration:
    let empty: HashMap[str, i32] = HashMap.new()
    var empty_count = 0
    for (_key, _value) in empty:
        empty_count = empty_count + 1
    assert(empty_count == 0)

    var map: HashMap[str, i32] = HashMap.new()
    map.insert("alpha", 1)
    map.insert("beta", 2)
    map.insert("alpha", 3)

    var saw_alpha = false
    var saw_beta = false
    var total = 0
    for (key, value) in map:
        if key == "alpha":
            saw_alpha = true
            assert(value == 3)
        if key == "beta":
            saw_beta = true
            assert(value == 2)
        total = total + value
    assert(saw_alpha)
    assert(saw_beta)
    assert(total == 5)

fn main:
    test_hashmap_values()
    test_hashmap_items()
    test_hashmap_direct_iteration()
    print("ok")
