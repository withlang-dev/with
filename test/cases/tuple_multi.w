// Test: tuples with more than 2 elements
fn make_triple(a: i32, b: i32, c: i32) -> (i32, i32, i32) =
    (a, b, c)

fn main() -> i32 =
    // 3-element tuple
    let t = (10, 20, 30)
    assert(t.0 == 10)
    assert(t.1 == 20)
    assert(t.2 == 30)

    // tuple from function
    let u = make_triple(1, 2, 3)
    assert(u.0 + u.1 + u.2 == 6)

    // destructuring 3-element tuple
    let (x, y, z) = (100, 200, 300)
    assert(x == 100)
    assert(y == 200)
    assert(z == 300)

    // 2-element tuple for comparison
    let pair = (42, 99)
    assert(pair.0 == 42)
    assert(pair.1 == 99)

    // tuple arithmetic
    let sum = t.0 + t.1 + t.2
    assert(sum == 60)

    println("all tuple multi tests passed")
    0
