// Test: Tuple destructuring in let bindings
fn swap(a: i32, b: i32) -> (i32, i32):
    (b, a)

fn main -> i32:
    // Basic tuple destructure
    let (x, y) = (10, 20)
    assert(x == 10)
    assert(y == 20)

    // Destructure function return
    let (a, b) = swap(1, 2)
    assert(a == 2)
    assert(b == 1)

    // Nested tuple
    let (p, q, r) = (100, 200, 300)
    assert(p == 100)
    assert(q == 200)
    assert(r == 300)

    println("all tuple destructure tests passed")
