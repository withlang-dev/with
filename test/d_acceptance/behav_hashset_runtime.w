fn main:
    var direct: HashSet[i32] = HashSet.new()
    direct.insert(4)
    assert(direct.contains(4))
    assert(direct.remove(4))
    assert(direct.len() == 0)

    let shared: HashSet[i32] = HashSet.new()
    shared.insert(7)
    let shared_ref = &shared
    assert(shared_ref.contains(7))
    assert(shared_ref.len() == 1)

    var shared_mut: HashSet[i32] = HashSet.new()
    shared_mut.insert(9)
    assert(shared_mut.remove(9))
    assert(shared_mut.len() == 0)

    let strings: HashSet[str] = HashSet.new()
    strings.insert("alpha")
    assert(strings.contains("alpha"))
    assert(not strings.contains("beta"))

    print("ok")
