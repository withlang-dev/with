//! expect-stdout: ok

// Tests: i8↔i32 roundtrip, u8↔u32 roundtrip, negative value casts,
//        boundary values, multi-step cast chains, cast in expressions

fn test_i8_to_i32_roundtrip:
    let a: i8 = -5
    let b: i32 = a as i32
    assert(b == -5)
    let c: i8 = b as i8
    assert(c == -5)

fn test_u8_to_u32_roundtrip:
    let a: u8 = 200u8
    let b: u32 = a as u32
    assert(b == 200u32)
    let c: u8 = b as u8
    assert(c == 200u8)

fn cast_i8_i32(x: i8) -> i32:
    x as i32

fn cast_i32_i8(x: i32) -> i8:
    x as i8

fn test_signed_roundtrip_via_fn:
    assert(cast_i8_i32(-1i8) == -1)
    assert(cast_i8_i32(127i8) == 127)
    assert(cast_i8_i32(-1i8) == -1)
    assert(cast_i32_i8(-1) == -1i8)
    assert(cast_i32_i8(42) == 42i8)

fn test_u32_to_u8_truncate:
    // Truncation: only low 8 bits kept
    let a: u32 = 0x1ABu32
    let b: u8 = a as u8
    assert(b == 0xABu8)
    // 256 truncates to 0
    let c: u32 = 256u32
    assert(c as u8 == 0u8)
    // 255 survives
    let d: u32 = 255u32
    assert(d as u8 == 255u8)

fn test_i64_to_i32_truncate:
    let a: i64 = 42i64
    let b: i32 = a as i32
    assert(b == 42)
    let c: i64 = -100i64
    assert(c as i32 == -100)

fn test_boundary_values:
    // u8 max → i32
    let a: u8 = 255u8
    assert(a as i32 == 255)
    // i8 min → i32 (-128 can't be written as -128i8; use typed let)
    let b: i8 = -127i8 - 1i8
    assert(b as i32 == -128)
    // i8 max → i32
    let c: i8 = 127i8
    assert(c as i32 == 127)

fn test_u8_to_i32_not_sign_extended:
    // u8 value 0xFF should become 255, not -1
    let a: u8 = 0xFFu8
    let b: i32 = a as i32
    assert(b == 255)
    assert(b > 0)

fn test_cast_chain:
    // u8 → u16 → u32 → u64 → i64
    let a: u8 = 42u8
    let b: i64 = (((a as u16) as u32) as u64) as i64
    assert(b == 42i64)

fn test_cast_in_arithmetic:
    let a: u8 = 10u8
    let b: u8 = 20u8
    // Cast to i32 to do arithmetic
    let sum: i32 = (a as i32) + (b as i32)
    assert(sum == 30)

fn main:
    test_i8_to_i32_roundtrip()
    test_u8_to_u32_roundtrip()
    test_signed_roundtrip_via_fn()
    test_u32_to_u8_truncate()
    test_i64_to_i32_truncate()
    test_boundary_values()
    test_u8_to_i32_not_sign_extended()
    test_cast_chain()
    test_cast_in_arithmetic()
    println("ok")
