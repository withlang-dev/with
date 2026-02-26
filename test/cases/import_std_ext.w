// Test: extended stdlib imports
use std.string
use std.math

fn main() -> i32 =
    // Test char functions from std.string
    assert(is_alpha(65))
    assert(not is_alpha(48))
    assert(is_digit(48))
    assert(not is_digit(65))
    assert(is_space(32))
    assert(not is_space(65))

    // Test math functions
    assert(abs(0 - 10) == 10)
    assert(min(3, 7) == 3)
    assert(max(3, 7) == 7)
    assert(clamp(50, 0, 100) == 50)
    assert(clamp(200, 0, 100) == 100)
    assert(clamp(0 - 5, 0, 100) == 0)

    // Test string_to_int
    assert(string_to_int("42") == 42)
    assert(string_to_int("-1") == -1)

    // Test string_eq
    assert(string_eq("hello", "hello"))
    assert(not string_eq("hello", "world"))

    0
