//! expect-stdout: ok

// Tests: int→float, float→int, float→float, implicit widening in return,
//        cast in expressions, f32/f64 precision, signed/unsigned float casts

fn test_int_to_float:
    let a: i32 = 42
    let b: f64 = a as f64
    assert(b as i64 == 42i64)
    let c: i32 = -10
    let d: f64 = c as f64
    assert(d as i64 == -10i64)

fn test_float_to_int:
    let a: f64 = 255.9
    let b: i32 = a as i32
    assert(b == 255)
    let c: f64 = -128.7
    let d: i32 = c as i32
    assert(d == -128)

fn test_float_to_int_boundary:
    let a: f64 = 0.0
    assert(a as i32 == 0)
    let b: f64 = 1.0
    assert(b as i32 == 1)
    let c: f64 = -1.0
    assert(c as i32 == -1)

fn int_to_f32(x: i32) -> f32:
    x as f32

fn int_to_f64(x: i32) -> f64:
    x as f64

fn test_int_to_float_via_fn:
    assert(int_to_f64(1234) as i64 == 1234i64)
    assert(int_to_f64(-2) as i64 == -2i64)
    assert(int_to_f32(1234) as i64 == 1234i64)
    assert(int_to_f32(-2) as i64 == -2i64)

fn test_f32_to_f64:
    let a: f32 = 3.5f32
    let b: f64 = a as f64
    assert(b as i64 == 3i64)
    // Value preserved through widening
    let c: f32 = 100.0f32
    let d: f64 = c as f64
    assert(d as i64 == 100i64)

fn test_f64_to_f32:
    let a: f64 = 42.0
    let b: f32 = a as f32
    assert(b as i64 == 42i64)

fn test_u8_to_f64:
    let a: u8 = 200u8
    let b: f64 = a as f64
    assert(b as i64 == 200i64)

fn test_u32_to_f64:
    let a: u32 = 1000000u32
    let b: f64 = a as f64
    assert(b as i64 == 1000000i64)

fn test_float_to_unsigned:
    let a: f64 = 200.0
    let b: u32 = a as u32
    assert(b == 200u32)

fn return_wider(x: i32) -> i64:
    // implicit widening in return
    x as i64

fn test_implicit_widen_return:
    assert(return_wider(42) == 42i64)
    assert(return_wider(-100) == -100i64)

fn test_cast_in_comparison:
    let a: u8 = 10u8
    let b: i32 = 10
    assert(a as i32 == b)

fn test_cast_in_arithmetic:
    let a: u8 = 50u8
    let b: u8 = 100u8
    // Widen to avoid overflow
    let c: i32 = (a as i32) * (b as i32)
    assert(c == 5000)

fn test_f64_to_i64:
    let a: f64 = 1000000.0
    assert(a as i64 == 1000000i64)
    let b: f64 = -999999.0
    assert(b as i64 == -999999i64)

fn test_i64_to_f64:
    let a: i64 = 1000000i64
    let b: f64 = a as f64
    assert(b as i64 == 1000000i64)

fn main:
    test_int_to_float()
    test_float_to_int()
    test_float_to_int_boundary()
    test_int_to_float_via_fn()
    test_f32_to_f64()
    test_f64_to_f32()
    test_u8_to_f64()
    test_u32_to_f64()
    test_float_to_unsigned()
    test_implicit_widen_return()
    test_cast_in_comparison()
    test_cast_in_arithmetic()
    test_f64_to_i64()
    test_i64_to_f64()
    print("ok")
