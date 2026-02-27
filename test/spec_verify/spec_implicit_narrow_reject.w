// NEGATIVE: i64 → i32 implicit narrowing should be rejected (§4.2)
// EXPECT: check fails with narrowing error
fn main -> i32:
    let x: i64 = 42
    let y: i32 = x
    0
