//! expect-stdout: ok

// Tests: integer widening (u8→u16→u32→u64), unsigned to signed widening,
//        float widening (f32→f64), small unsigned to larger signed

fn test_unsigned_widening:
    let a: u8 = 250u8
    let b: u16 = a as u16
    let c: u32 = b as u32
    let d: u64 = c as u64
    assert(d == 250u64)
    assert(a as u64 == d)

fn test_unsigned_to_signed:
    // u8 → i16: 250 stays 250 (zero-extended, not sign-extended)
    let a: u8 = 250u8
    let b: i32 = a as i32
    assert(b == 250)
    // u16 → i32
    let c: u16 = 60000u16
    let d: i32 = c as i32
    assert(d == 60000)

fn cast_u8_to_i16(x: u8) -> i32:
    x as i32

fn cast_u16_to_i64(x: u16) -> i64:
    x as i64

fn test_small_unsigned_to_larger_signed:
    assert(cast_u8_to_i16(200u8) == 200)
    assert(cast_u16_to_i64(9999u16) == 9999i64)
    // Edge: maximum u8 → i32 should be 255, not -1
    assert(cast_u8_to_i16(255u8) == 255)

fn test_float_widening:
    let a: f32 = 12.5
    let b: f64 = a as f64
    // After widening, value should be preserved
    assert(b as i64 == 12i64)
    // f32 max precision preserved in f64
    let c: f32 = 1000.25
    let d: f64 = c as f64
    assert(d as i64 == 1000i64)

fn test_signed_widening:
    // Negative values should be sign-extended
    let a: i32 = -42
    let b: i64 = a as i64
    assert(b == -42i64)
    // i32 max
    let c: i32 = 2147483647
    let d: i64 = c as i64
    assert(d == 2147483647i64)

fn main:
    test_unsigned_widening()
    test_unsigned_to_signed()
    test_small_unsigned_to_larger_signed()
    test_float_widening()
    test_signed_widening()
    println("ok")
