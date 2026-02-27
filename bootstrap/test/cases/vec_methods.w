// Test: Vec methods
fn main -> i32:
    // Create vec and push elements
    var v = Vec.new()
    v.push(10)
    v.push(20)
    v.push(30)

    // .len()
    assert(v.len() == 3)

    // .get()
    assert(v.get(0) == 10)
    assert(v.get(1) == 20)
    assert(v.get(2) == 30)

    // .is_empty()
    assert(not v.is_empty())

    // .pop()
    let popped = v.pop()
    assert(popped.is_some())
    assert(popped.unwrap() == 30)
    assert(v.len() == 2)

    // Vec.of()
    let v2 = Vec.of(1, 2, 3, 4, 5)
    assert(v2.len() == 5)
    assert(v2.get(0) == 1)
    assert(v2.get(4) == 5)

    // Empty vec
    var empty = Vec.new()
    assert(empty.is_empty())
    let p = empty.pop()
    assert(p.is_none())

    println("all vec method tests passed")
