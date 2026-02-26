// Test: stdlib import
use std.string
use std.math

fn main -> i32:
    // Test string functions
    let len = string_len("hello")
    assert(len == 5)

    let eq = string_eq("abc", "abc")
    assert(eq)

    let neq = string_eq("abc", "def")
    assert(not neq)

    // Test math functions
    let a = abs(0 - 42)
    assert(a == 42)

    let m = min(10, 20)
    assert(m == 10)

    let x = max(10, 20)
    assert(x == 20)

    let c = clamp(50, 0, 100)
    assert(c == 50)

    let c2 = clamp(0 - 5, 0, 100)
    assert(c2 == 0)

