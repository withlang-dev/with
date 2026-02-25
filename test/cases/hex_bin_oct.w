// Test: Hex, binary, octal literals
fn main() -> i32 =
    let hex = 0xFF
    assert(hex == 255)
    let bin = 0b1010
    assert(bin == 10)
    let oct = 0o77
    assert(oct == 63)
    0
