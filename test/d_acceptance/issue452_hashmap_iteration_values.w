//! expect-stdout: ok

// D44: values() and iter() observe; an owned List is collected where it is
// wanted. D96: entries keep the position of their first insertion.
fn test_hashmap_values:
    let empty: HashMap[str, i32] = HashMap.new()
    assert(empty.values() |> count() == 0)

    var map: HashMap[str, i32] = HashMap.new()
    map.insert("alpha", 1)
    map.insert("beta", 2)
    map.insert("alpha", 3)

    let values = map.values() |> map(it.clone()) |> collect[List]()
    assert(values == [3, 2])

fn test_hashmap_iter:
    var map: HashMap[str, i32] = HashMap.new()
    map.insert("alpha", 1)
    map.insert("beta", 2)
    map.insert("alpha", 3)

    var seen = ""
    var total = 0
    for (key, value) in map.iter():
        seen = seen ++ key
        total = total + value
    assert(seen == "alphabeta")
    assert(total == 5)
    assert(map.len() == 2)

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
    test_hashmap_iter()
    test_hashmap_direct_iteration()
    print("ok")
