// Test: §19.5 place-yielding iteration via ListIterPlace

fn test_iter_place_set_all:
    var xs = List.new()
    xs.push(10)
    xs.push(20)
    xs.push(30)
    for slot in xs.iter_place():
        slot.set(0)
    assert(xs[0] == 0)
    assert(xs[1] == 0)
    assert(xs[2] == 0)

fn test_iter_place_increment:
    var xs = List.new()
    xs.push(1)
    xs.push(2)
    xs.push(3)
    for slot in xs.iter_place():
        let v = slot.get()
        slot.set(v + 10)
    assert(xs[0] == 11)
    assert(xs[1] == 12)
    assert(xs[2] == 13)

fn test_iter_place_empty:
    var xs: List[i32] = List.new()
    for slot in xs.iter_place():
        slot.set(99)
    assert(xs.len() == 0)
