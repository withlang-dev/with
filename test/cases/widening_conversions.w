//! expect-stdout: ok

// Test: implicit widening conversions
// Covers signed widening, float, arithmetic widening, function args.

fn accept_i64(x: i64) -> i64: x

fn test_let_binding_widening:
    // i32 -> i64 in let binding
    let x: i32 = 42
    let y: i64 = x
    assert(y == 42)

fn test_fn_arg_widening:
    // i32 -> i64 in function argument
    let x: i32 = 42
    let z = accept_i64(x)
    assert(z == 42)

fn test_arithmetic_widening:
    // i32 + i64 -> i64
    let a: i32 = 10
    let b: i64 = 20
    let c = a + b
    assert(c == 30)

fn main:
    test_let_binding_widening()
    test_fn_arg_widening()
    test_arithmetic_widening()
    println("ok")
