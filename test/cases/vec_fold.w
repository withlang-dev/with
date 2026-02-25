// Test: Vec fold, map, filter methods
fn add(a: i32, b: i32) -> i32 = a + b
fn double(x: i32) -> i32 = x * 2
fn is_even(x: i32) -> bool = x % 2 == 0

fn main() -> i32 =
    var v: Vec[i32] = Vec.new()
    v.push(1)
    v.push(2)
    v.push(3)
    v.push(4)
    v.push(5)

    // fold: sum all elements
    let sum = v.fold(0, add)
    assert(sum == 15)

    // map: double each element
    let doubled = v.map(double)
    assert(doubled.get(0) == 2)
    assert(doubled.get(1) == 4)
    assert(doubled.get(2) == 6)
    assert(doubled.len() == 5)

    // filter: keep only even numbers
    let evens = v.filter(is_even)
    assert(evens.len() == 2)
    assert(evens.get(0) == 2)
    assert(evens.get(1) == 4)

    println("all vec fold tests passed")
    0
