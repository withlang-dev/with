// Spec test: Section 6 - Handles and SlotMap

fn test_insert_get_contains_len:
    var map = SlotMap[i32].new()
    let h = map.insert(10)
    assert(map.len() == 1)
    assert(map.contains(h))
    match map.get(h):
        Some(v) => assert(*v == 10)
        None => assert(false)

fn test_remove_replace_invalidates_stale_handle:
    var map = SlotMap[i32].new()
    let h1 = map.insert(10)
    match map.replace(h1, 15):
        Some(old) => assert(old == 10)
        None => assert(false)
    match map.get(h1):
        Some(v) => assert(*v == 15)
        None => assert(false)
    match map.remove(h1):
        Some(old) => assert(old == 15)
        None => assert(false)
    assert(map.len() == 0)
    assert(not map.contains(h1))
    match map.get(h1):
        Some(_) => assert(false)
        None => assert(true)

    let h2 = map.insert(20)
    assert(h2.index == h1.index)
    assert(h2.generation != h1.generation)
    match map.get(h2):
        Some(v2) => assert(*v2 == 20)
        None => assert(false)

fn test_slot_and_get_disjoint:
    var map = SlotMap[i32].new()
    let a = map.insert(1)
    let b = map.insert(2)
    with map.slot(a) as mut s:
        s.set(10)
    with map.get_disjoint(a, b) as mut (left, right):
        let old_left = left.get()
        left.set(right.get())
        right.set(old_left)
    match map.get(a):
        Some(v) => assert(*v == 2)
        None => assert(false)
    match map.get(b):
        Some(v) => assert(*v == 10)
        None => assert(false)

fn test_handles_in_containers:
    var map = SlotMap[str].new()
    let h1 = map.insert("hello")
    let h2 = map.insert("world")
    var handles = Vec[Handle[str]].new()
    handles.push(h1)
    handles.push(h2)
    assert(handles.len() == 2)
    assert(map.contains(handles.get(0)))
    assert(map.contains(handles.get(1)))
