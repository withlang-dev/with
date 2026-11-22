//! expect-stdout: ok

// Behavior test: type casting (as)
// Tests: i32<->i64, bool->i32, widening, narrowing

fn test_i32_to_i64:
    let x: i32 = 42
    let y: i64 = x as i64
    assert(y == 42)

fn test_i64_to_i32:
    let x: i64 = 100
    let y: i32 = x as i32
    assert(y == 100)

fn test_negative_cast:
    let x: i32 = -5
    let y: i64 = x as i64
    assert(y == -5)

fn test_bool_to_i32:
    let t = true
    let f = false
    assert(t as i32 == 1)
    assert(f as i32 == 0)

fn test_bool_to_i64:
    let t = true
    let f = false
    assert(t as i64 == 1)
    assert(f as i64 == 0)

fn test_comparison_cast:
    let x = 10
    let cmp = x > 5
    assert(cmp as i32 == 1)
    let cmp2 = x < 5
    assert(cmp2 as i32 == 0)

fn test_cast_in_expression:
    let a: i32 = 10
    let b: i64 = 20
    let sum: i64 = (a as i64) + b
    assert(sum == 30)

fn main:
    test_i32_to_i64()
    test_i64_to_i32()
    test_negative_cast()
    test_bool_to_i32()
    test_bool_to_i64()
    test_comparison_cast()
    test_cast_in_expression()
    print("ok")
