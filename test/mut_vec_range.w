// Test: Vec.range(start..end) scoped sub-range view

fn test_range_read:
    var xs = Vec.new()
    xs.push(10)
    xs.push(20)
    xs.push(30)
    xs.push(40)
    let r = xs.range(1..3)
    assert(r.get(0) == 20)
    assert(r.get(1) == 30)
    assert(r.len() == 2)

fn test_range_write:
    var xs = Vec.new()
    xs.push(10)
    xs.push(20)
    xs.push(30)
    xs.push(40)
    with xs.range(1..3) as mut r:
        r.set(0, 99)
        r.set(1, 88)
    assert(xs.get(1) == 99)
    assert(xs.get(2) == 88)
    assert(xs.get(0) == 10)
    assert(xs.get(3) == 40)

fn test_range_len:
    var xs = Vec.new()
    xs.push(1)
    xs.push(2)
    xs.push(3)
    xs.push(4)
    xs.push(5)
    let r = xs.range(0..5)
    assert(r.len() == 5)
    let r2 = xs.range(2..4)
    assert(r2.len() == 2)
