// Test: all bitwise operations (&, |, ^, <<, >>)
fn main() -> i32 =
    // AND
    let a = 0xFF & 0x0F
    assert(a == 15)

    // OR
    let b = 0xF0 | 0x0F
    assert(b == 255)

    // XOR
    let c = 0xFF ^ 0x0F
    assert(c == 240)

    // left shift
    let d = 1 << 4
    assert(d == 16)

    let e = 3 << 3
    assert(e == 24)

    // right shift
    let f = 128 >> 3
    assert(f == 16)

    let g = 255 >> 4
    assert(g == 15)

    // combined operations
    let h = (1 << 8) - 1
    assert(h == 255)

    let i = (0xAB & 0xF0) >> 4
    assert(i == 10)

    let j = (0x05 << 4) | 0x03
    assert(j == 83)

    // XOR self gives 0
    let k = 42 ^ 42
    assert(k == 0)

    // AND with 0 gives 0
    let l = 12345 & 0
    assert(l == 0)

    // OR with 0 is identity
    let m = 42 | 0
    assert(m == 42)

    // hex literal shifts
    let n = 0x01 << 7
    assert(n == 128)

    println("all bitwise advanced tests passed")
    0
