// NEGATIVE: int -> float implicit conversion is rejected (§4.2)
// EXPECT: check fails with narrowing/type error

fn main:
    let count: i32 = 3
    let ratio: f64 = count
    let _ = ratio
