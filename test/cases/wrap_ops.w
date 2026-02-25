// Test: Wrapping arithmetic operators (+%, -%, *%)
fn main() -> i32 =
    // Basic wrapping addition
    let a: i32 = 100
    let b: i32 = 200
    assert(a +% b == 300)

    // Basic wrapping subtraction
    assert(b -% a == 100)

    // Basic wrapping multiplication
    let c: i32 = 10
    let d: i32 = 20
    assert(c *% d == 200)

    // Wrapping on overflow (i32 max is 2147483647)
    let big: i32 = 2147483647
    let wrapped = big +% 1
    // Should wrap to -2147483648
    assert(wrapped == 0 - 2147483648)

    println("all wrapping ops tests passed")
    0
