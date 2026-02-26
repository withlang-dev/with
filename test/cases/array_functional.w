// Test: functional array methods (map, reduce, sum)
fn double(x: i32) -> i32: x * 2

fn add(a: i32, b: i32) -> i32: a + b

fn main -> i32:
    let arr = [1, 2, 3, 4, 5]

    // sum
    let s = arr.sum()
    assert(s == 15)

    // map
    let doubled = arr.map(double)
    assert(doubled.first() == 2)
    assert(doubled.last() == 10)
    assert(doubled.sum() == 30)

    // reduce
    let total = arr.reduce(add, 0)
    assert(total == 15)

    // reduce with initial value
    let total2 = arr.reduce(add, 100)
    assert(total2 == 115)

