//! expect-stdout: ok

// Tests: integer truncation via `as` — u32→u8, u64→u16, i64→i32,
//        u64→u8, truncation preserves low bits, sign behavior

fn test_u32_to_u8:
    let a: u32 = 0xABCDu32
    assert(a as u8 == 0xCDu8)
    let b: u32 = 0u32
    assert(b as u8 == 0u8)
    let c: u32 = 255u32
    assert(c as u8 == 255u8)
    let d: u32 = 256u32
    assert(d as u8 == 0u8)

fn test_u64_to_u16:
    let a: u64 = 0x123456789ABCu64
    assert(a as u16 == 0x9ABCu16)
    let b: u64 = 65535u64
    assert(b as u16 == 65535u16)
    let c: u64 = 65536u64
    assert(c as u16 == 0u16)

fn test_u64_to_u8:
    let a: u64 = 0x12345678ABCDu64
    assert(a as u8 == 0xCDu8)
    let b: u64 = 0x100u64
    assert(b as u8 == 0u8)

fn trunc_u32_u8(x: u32) -> u8:
    x as u8

fn trunc_u64_u16(x: u64) -> u16:
    x as u16

fn test_truncate_via_fn:
    assert(trunc_u32_u8(0xFFu32) == 255u8)
    assert(trunc_u32_u8(0x100u32) == 0u8)
    assert(trunc_u32_u8(0x1FFu32) == 255u8)
    assert(trunc_u64_u16(0x10000u64) == 0u16)
    assert(trunc_u64_u16(0x1FFFFu64) == 65535u16)

fn test_i64_to_i32:
    let a: i64 = 2147483647i64
    assert(a as i32 == 2147483647)
    let b: i64 = -2147483648i64
    assert(b as i32 == -2147483648)
    let c: i64 = 42i64
    assert(c as i32 == 42)
    let d: i64 = -42i64
    assert(d as i32 == -42)

fn test_i32_to_i8:
    let a: i32 = 127
    assert(a as i8 == 127i8)
    let b: i32 = -128
    let b_i8: i8 = b as i8
    let expected: i8 = -127i8 - 1i8
    assert(b_i8 == expected)
    let c: i32 = 0
    assert(c as i8 == 0i8)

fn test_truncate_low_bits_preserved:
    // The key property: truncation preserves the low N bits
    let x: u32 = 0xDEADBEEFu32
    assert(x as u8 == 0xEFu8)
    assert(x as u16 == 0xBEEFu16)

fn main:
    test_u32_to_u8()
    test_u64_to_u16()
    test_u64_to_u8()
    test_truncate_via_fn()
    test_i64_to_i32()
    test_i32_to_i8()
    test_truncate_low_bits_preserved()
    print("ok")
