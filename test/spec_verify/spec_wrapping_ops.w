// POSITIVE: Wrapping arithmetic operators +% -% *% (§4.2)
fn main -> i32:
    // Wrapping addition: i32 max + 1 wraps to min
    let big: i32 = 2147483647
    let wrapped = big +% 1
    assert(wrapped == 0 - 2147483648)

    // Wrapping subtraction
    let a: i32 = 100
    let b: i32 = 200
    assert(b -% a == 100)

    // Wrapping multiplication
    let c: i32 = 10
    let d: i32 = 20
    assert(c *% d == 200)

    println("wrapping ops ok")
