fn main() -> i32 =
    let a = 0xFF
    let b = 0x0F
    let c = a & b
    let d = c | 0x20
    let e = d ^ 0x0F
    assert(e == 32)
    0
