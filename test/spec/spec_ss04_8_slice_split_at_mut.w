//! expect-stdout: ok

fn test_vec_split_at_mut:
    var xs = Vec.new()
    xs.push(1)
    xs.push(2)
    xs.push(3)
    xs.push(4)
    let (left, right) = xs.split_at_mut(2)
    left.set(0, 11)
    left.set(1, 12)
    right.set(0, 13)
    right.set(1, 14)
    assert(xs.get(0) == 11)
    assert(xs.get(1) == 12)
    assert(xs.get(2) == 13)
    assert(xs.get(3) == 14)

fn test_array_split_at_mut:
    var xs = [5, 6, 7, 8]
    let (left, right) = xs.split_at_mut(2)
    left.set(0, 50)
    right.set(1, 80)
    assert(xs[0] == 50)
    assert(xs[1] == 6)
    assert(xs[2] == 7)
    assert(xs[3] == 80)

fn test_slice_split_at_mut:
    var xs = [10, 20, 30, 40]
    var middle = xs[1..4]
    let (left, right) = middle.split_at_mut(1)
    if left.len() > 0:
        left.set(0, left.get(0) + 10)
    if right.len() > 0:
        right.set(0, right.get(0) + 10)
    assert(xs[0] == 10)
    assert(xs[1] == 30)
    assert(xs[2] == 40)
    assert(xs[3] == 40)

fn test_range_split_at_mut:
    var xs = Vec.new()
    xs.push(100)
    xs.push(200)
    xs.push(300)
    xs.push(400)
    with xs.range(1..4) as mut middle:
        let (left, right) = middle.split_at_mut(1)
        left.set(0, 201)
        right.set(1, 401)
    assert(xs.get(0) == 100)
    assert(xs.get(1) == 201)
    assert(xs.get(2) == 300)
    assert(xs.get(3) == 401)

fn main:
    test_vec_split_at_mut()
    test_array_split_at_mut()
    test_slice_split_at_mut()
    test_range_split_at_mut()
    print("ok")
