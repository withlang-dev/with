// Test: Vec[T] dynamic array
fn main -> i32:
    // Create from Vec.of()
    var v = Vec.of(10, 20, 30)
    assert(v.len() == 3)
    assert(v.get(0) == 10)
    assert(v.get(1) == 20)
    assert(v.get(2) == 30)

    // Push
    v.push(40)
    assert(v.len() == 4)
    assert(v.get(3) == 40)

    // Pop
    let last = v.pop()
    assert(last.unwrap() == 40)
    assert(v.len() == 3)

    // is_empty
    assert(not v.is_empty())

    // Push many (tests realloc/growth)
    v.push(50)
    v.push(60)
    v.push(70)
    v.push(80)
    v.push(90)
    assert(v.len() == 8)
    assert(v.get(7) == 90)

