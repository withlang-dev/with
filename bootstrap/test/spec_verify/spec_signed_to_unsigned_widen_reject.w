// NEGATIVE: signed -> unsigned is never implicit, even when destination is wider (§4.2)
// EXPECT: check fails with narrowing/type error

fn get_i8() -> i8:
    let raw: i32 = 7
    raw as i8

fn main:
    let x: i8 = get_i8()
    let y: u16 = x
    let _ = y
