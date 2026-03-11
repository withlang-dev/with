//! expect-stdout: ok

// Behavior test: integer type casting
// Tests: i32<->i64, bool->i32, narrowing, widening

fn test_i32_to_i64_widening:
    let x: i32 = 42
    let y: i64 = x as i64
    assert(y == 42)

fn test_negative_widening:
    let x: i32 = -5
    let y: i64 = x as i64
    assert(y == -5)

fn test_narrowing:
    let x: i64 = 100
    let y: i32 = x as i32
    assert(y == 100)

fn test_bool_to_int:
    let t = true
    let f = false
    assert(t as i32 == 1)
    assert(f as i32 == 0)

fn test_int_comparison_cast:
    let x = 10
    let cmp = x > 5
    assert(cmp as i32 == 1)
    let cmp2 = x < 5
    assert(cmp2 as i32 == 0)

fn main:
    test_i32_to_i64_widening()
    test_negative_widening()
    test_narrowing()
    test_bool_to_int()
    test_int_comparison_cast()
    println("ok")
