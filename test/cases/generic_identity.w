// Test: generic identity function with multiple type instantiations
fn identity[T](x: T) -> T =
    x

fn first[T](a: T, b: T) -> T =
    a

fn second[T](a: T, b: T) -> T =
    b

fn main() -> i32 =
    // identity with i32
    let a = identity(42)
    assert(a == 42)

    // identity with i64
    let b: i64 = 100
    let c = identity(b)
    assert(c as i32 == 100)

    // identity with bool
    let d = identity(true)
    assert(d)

    // first and second with i32
    let e = first(10, 20)
    assert(e == 10)

    let f = second(10, 20)
    assert(f == 20)

    // chained generic calls
    let g = identity(identity(identity(7)))
    assert(g == 7)

    // generic with expression argument
    let h = identity(3 + 4)
    assert(h == 7)

    println("all generic identity tests passed")
    0
