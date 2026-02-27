// NEGATIVE: i32 → u32 implicit conversion should be rejected (§4.2)
// EXPECT: check fails with narrowing error

fn get_i32() -> i32:
    42

fn main -> i32:
    let x: i32 = get_i32()
    let y: u32 = x
    0
