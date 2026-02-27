// NEGATIVE: u32 → i32 implicit conversion should be rejected (§4.2)
// Same bit width, different signedness — spec says this needs explicit `as`
// EXPECT: check fails with narrowing/type error

fn get_u32() -> u32:
    let val: i32 = 42
    val as u32

fn main -> i32:
    let x: u32 = get_u32()
    let y: i32 = x
    0
