// Vec iteration via for-in loop (the standard way to iterate)
fn main -> i32:
    let v = Vec.of(10, 20, 30, 40, 50)
    var sum = 0
    for x in v
        sum = sum + x
    assert(sum == 150)

    // for-in with indexed access
    let v2 = Vec.of(1, 2, 3)
    var product = 1
    for x in v2
        product = product * x
    assert(product == 6)

    println("vec iteration passed")
