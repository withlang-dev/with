// Test: Vec[T] with type annotation
fn main -> i32:
    var v: Vec[i32] = Vec.new()
    assert(v.is_empty())
    assert(v.len() == 0)

    v.push(100)
    v.push(200)
    assert(v.len() == 2)
    assert(v.get(0) == 100)
    assert(v.get(1) == 200)

    // Pop all
    let b = v.pop()
    assert(b.unwrap() == 200)
    let a = v.pop()
    assert(a.unwrap() == 100)
    assert(v.is_empty())

    // Pop from empty returns None
    let empty = v.pop()
    assert(empty.is_none())

