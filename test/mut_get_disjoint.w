// Test: Vec.get_disjoint(i, j) returns (VecSlot[T], VecSlot[T])

fn test_basic_swap:
    var xs = Vec.new()
    xs.push(10)
    xs.push(20)
    xs.push(30)
    let slots = xs.get_disjoint(0, 2)
    with slots as mut (a, b):
        let tmp = a.get()
        a.set(b.get())
        b.set(tmp)
    assert(xs.get(0) == 30)
    assert(xs.get(1) == 20)
    assert(xs.get(2) == 10)

fn test_independent_mutation:
    var xs = Vec.new()
    xs.push(1)
    xs.push(2)
    xs.push(3)
    with xs.get_disjoint(0, 1) as mut (a, b):
        a.set(100)
        b.set(200)
    assert(xs.get(0) == 100)
    assert(xs.get(1) == 200)
    assert(xs.get(2) == 3)

fn test_read_only:
    var xs = Vec.new()
    xs.push(5)
    xs.push(10)
    xs.push(15)
    with xs.get_disjoint(1, 2) as (a, b):
        assert(a.get() == 10)
        assert(b.get() == 15)
