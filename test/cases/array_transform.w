// Test: array.map and array.reduce transformations
fn triple(x: i32) -> i32 = x * 3

fn add(a: i32, b: i32) -> i32 = a + b

fn mul(a: i32, b: i32) -> i32 = a * b

fn main() -> i32 =
    let arr = [1, 2, 3, 4, 5]

    // map with triple
    let tripled = arr.map(triple)
    assert(tripled.first() == 3)
    assert(tripled.last() == 15)
    assert(tripled.sum() == 45)

    // reduce with add (sum)
    let total = arr.reduce(add, 0)
    assert(total == 15)

    // reduce with multiply (product)
    let product = arr.reduce(mul, 1)
    assert(product == 120)

    // sum built-in
    assert(arr.sum() == 15)

    // map then sum
    let doubled_sum = arr.map(triple).sum()
    assert(doubled_sum == 45)

    // contains
    assert(arr.contains(3))
    assert(not arr.contains(99))

    // len
    assert(arr.len == 5)

    println("all array transform tests passed")
    0
