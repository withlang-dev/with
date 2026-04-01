fn main:
    let map: HashMap[str, i32] = HashMap.new()
    map.insert("a", 1)
    map.insert("b", 2)
    let map_ref = &map
    assert(map_ref.contains("a"))
    assert(map_ref.get("b").unwrap() == 2)

    var map_mut: HashMap[str, i32] = HashMap.new()
    map_mut.insert("x", 9)
    map_mut.insert("y", 8)
    let map_mut_ref = &mut map_mut
    assert(map_mut_ref.remove("x").unwrap() == 9)
    assert(map_mut_ref.len() == 1)

    let set: HashSet[i32] = HashSet.new()
    set.insert(4)
    let set_ref = &set
    assert(set_ref.contains(4))

    var set_mut: HashSet[i32] = HashSet.new()
    set_mut.insert(5)
    let set_mut_ref = &mut set_mut
    assert(set_mut_ref.remove(5))
    assert(set_mut_ref.len() == 0)
