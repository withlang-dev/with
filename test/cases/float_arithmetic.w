// Test: comprehensive float operations (f32/f64, arithmetic, casting)
fn main() -> i32 =
    // basic f64 arithmetic
    let a = 3.14
    let b = 2.0
    let c = a + b
    assert(c as i32 == 5)

    let d = a * b
    assert(d as i32 == 6)

    let e = 10.0 - 3.5
    assert(e as i32 == 6)

    let f = 10.0 / 4.0
    assert(f as i32 == 2)

    // float comparison via casting
    let g = 7.9
    assert(g as i32 == 7)

    let h = 0.5
    assert(h as i32 == 0)

    // negative floats
    let neg = 0.0 - 5.5
    assert(neg as i32 == 0 - 5)

    // int to float casting
    let x: i32 = 42
    let y = x as f64
    let z = y + 0.5
    assert(z as i32 == 42)

    // float multiplication chain
    let m = 2.5 * 4.0
    assert(m as i32 == 10)

    // large float values
    let big = 1000.0 + 234.0
    assert(big as i32 == 1234)

    println("all float arithmetic tests passed")
    0
