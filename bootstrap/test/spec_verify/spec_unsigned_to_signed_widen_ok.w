// POSITIVE: wider unsigned -> signed implicit conversion is allowed (§4.2)

fn get_u32() -> u32:
    let raw: i64 = 42
    raw as u32

fn main:
    let x: u32 = get_u32()
    let y: i64 = x
    assert(y == 42)
