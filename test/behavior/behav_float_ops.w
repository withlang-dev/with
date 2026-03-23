//! expect-stdout: ok

// Tests: float arithmetic, float comparison, float→int, int→float,
//        f32 vs f64, float in expressions, negative floats

fn test_float_arithmetic:
    let a: f64 = 3.0
    let b: f64 = 4.0
    assert((a + b) as i64 == 7i64)
    assert((a * b) as i64 == 12i64)
    assert((b - a) as i64 == 1i64)
    assert((b / a) as i64 == 1i64)

fn test_float_negative:
    let a: f64 = -5.5
    assert(a as i64 == -5i64)
    let b: f64 = -a
    assert(b as i64 == 5i64)

fn test_float_comparison:
    let a: f64 = 1.5
    let b: f64 = 2.5
    assert(a < b)
    assert(b > a)
    assert(a != b)
    assert(a == 1.5)

fn test_f32_arithmetic:
    let a: f32 = 10.0f32
    let b: f32 = 3.0f32
    let c: f32 = a + b
    assert(c as i64 == 13i64)
    let d: f32 = a * b
    assert(d as i64 == 30i64)

fn test_float_to_int_truncation:
    // Float-to-int truncates toward zero
    let a: f64 = 3.9
    assert(a as i32 == 3)
    let b: f64 = -3.9
    assert(b as i32 == -3)
    let c: f64 = 0.99
    assert(c as i32 == 0)

fn test_int_to_float:
    let a: i32 = 42
    let b: f64 = a as f64
    assert(b as i64 == 42i64)
    let c: i32 = -100
    let d: f64 = c as f64
    assert(d as i64 == -100i64)

fn test_f32_to_f64:
    let a: f32 = 100.0f32
    let b: f64 = a as f64
    assert(b as i64 == 100i64)

fn test_f64_to_f32:
    let a: f64 = 42.0
    let b: f32 = a as f32
    assert(b as i64 == 42i64)

fn test_float_accumulator:
    var sum: f64 = 0.0
    var i = 1
    while i <= 10:
        sum = sum + (i as f64)
        i = i + 1
    assert(sum as i64 == 55i64)

fn lerp(a: f64, b: f64, t: f64) -> f64:
    a + (b - a) * t

fn test_float_interpolation:
    let result = lerp(0.0, 100.0, 0.5)
    assert(result as i64 == 50i64)
    let result2 = lerp(0.0, 100.0, 0.0)
    assert(result2 as i64 == 0i64)
    let result3 = lerp(0.0, 100.0, 1.0)
    assert(result3 as i64 == 100i64)

fn test_float_large_values:
    let a: f64 = 1000000.0
    let b: f64 = 2000000.0
    let c = a * b
    assert(c as i64 == 2000000000000i64)

fn main:
    test_float_arithmetic()
    test_float_negative()
    test_float_comparison()
    test_f32_arithmetic()
    test_float_to_int_truncation()
    test_int_to_float()
    test_f32_to_f64()
    test_f64_to_f32()
    test_float_accumulator()
    test_float_interpolation()
    test_float_large_values()
    println("ok")
