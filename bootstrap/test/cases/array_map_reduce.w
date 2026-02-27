// Test: array map and reduce chains
fn square(x: i32) -> i32: x * x
fn triple(x: i32) -> i32: x * 3
fn add(a: i32, b: i32) -> i32: a + b
fn mul(a: i32, b: i32) -> i32: a * b
fn max_fn(a: i32, b: i32) -> i32:
    if a > b then a else b

fn main -> i32:
    let arr = [1, 2, 3, 4, 5]

    // map then sum
    let squares = arr.map(square)
    let sum_sq = squares.sum()
    // 1+4+9+16+25 = 55
    assert(sum_sq == 55)

    // map then reduce
    let tripled = arr.map(triple)
    let sum_tripled = tripled.reduce(add, 0)
    // 3+6+9+12+15 = 45
    assert(sum_tripled == 45)

    // reduce with multiplication (factorial-like)
    let product = arr.reduce(mul, 1)
    // 1*2*3*4*5 = 120
    assert(product == 120)

    // reduce to find max
    let arr2 = [3, 7, 2, 9, 1]
    let max_val = arr2.reduce(max_fn, 0)
    assert(max_val == 9)

    // map + first/last
    let doubled = arr.map(triple)
    assert(doubled.first() == 3)
    assert(doubled.last() == 15)

    // Chained: sum of squares
    let arr3 = [2, 3, 4]
    let mapped = arr3.map(square)
    let total = mapped.reduce(add, 0)
    // 4+9+16 = 29
    assert(total == 29)

    // reduce with initial value
    let arr4 = [1, 2, 3]
    let with_init = arr4.reduce(add, 100)
    assert(with_init == 106)

    println("all array_map_reduce tests passed")
