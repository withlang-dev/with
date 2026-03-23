//! expect-stdout: ok

// Behavior test: move semantics — ownership transfer, copy types
// Copy types (i32, bool, f64) are copied on assignment.
// Non-copy types (str used as owned) transfer ownership.

fn test_copy_i32:
    let a = 42
    let b = a
    // Both a and b are valid for copy types
    assert(a == 42)
    assert(b == 42)

fn test_copy_bool:
    let a = true
    let b = a
    assert(a == true)
    assert(b == true)

fn test_copy_in_loop:
    let x = 10
    var sum = 0
    for i in 0..5:
        sum = sum + x  // x is copied each iteration
    assert(sum == 50)
    assert(x == 10)  // x still valid

fn test_copy_to_function:
    let n = 7
    let r = double(n)
    assert(r == 14)
    assert(n == 7)  // n still valid after pass

fn double(x: i32) -> i32:
    x * 2

fn test_var_reassign:
    var x = 10
    x = 20
    assert(x == 20)
    x = x + 5
    assert(x == 25)

fn test_shadow_move:
    var x = 100
    x = x + 1  // mutate, not shadow
    assert(x == 101)

fn consume_string(s: str) -> i32:
    if s == "hello":
        1
    else:
        0

fn test_string_pass:
    let s = "hello"
    let r = consume_string(s)
    assert(r == 1)

fn main:
    test_copy_i32()
    test_copy_bool()
    test_copy_in_loop()
    test_copy_to_function()
    test_var_reassign()
    test_shadow_move()
    test_string_pass()
    println("ok")
