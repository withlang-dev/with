// POSITIVE: i32 → i64 implicit widening should succeed (§4.2)
fn main -> i32:
    let a: i32 = 42
    let b: i64 = a
    println("widening ok")
