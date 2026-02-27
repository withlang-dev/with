// Test: for-in loop over Vec
fn main -> i32:
    let v = Vec.of(10, 20, 30, 40, 50)
    var sum = 0
    for x in v
        sum = sum + x
    assert(sum == 150)

    // for-in with single element
    let v2 = Vec.of(42)
    var total = 0
    for x in v2
        total = total + x
    assert(total == 42)

    println("all for-vec tests passed")
