// Test: §19.5 place-yielding iteration via VecIterPlace

fn test_iter_place_set_all:
    var xs = Vec.new()
    xs.push(10)
    xs.push(20)
    xs.push(30)
    for slot in xs.iter_place():
        slot.set(0)
    assert(xs.get(0) == 0)
    assert(xs.get(1) == 0)
    assert(xs.get(2) == 0)

fn test_iter_place_increment:
    var xs = Vec.new()
    xs.push(1)
    xs.push(2)
    xs.push(3)
    for slot in xs.iter_place():
        let v = slot.get()
        slot.set(v + 10)
    assert(xs.get(0) == 11)
    assert(xs.get(1) == 12)
    assert(xs.get(2) == 13)

fn test_iter_place_empty:
    var xs: Vec[i32] = Vec.new()
    for slot in xs.iter_place():
        slot.set(99)
    assert(xs.len() == 0)
