fn main() -> i32 =
    let a = 0xFF
    let b = 0x0F
    let c = a & b
    assert(c == 15)
    let d = a | b
    assert(d == 255)
    let e = a ^ b
    assert(e == 240)
    println("bitwise and/or/xor pass")
    0
