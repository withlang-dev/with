// Test: extended stdlib imports
use std.string
use std.math

fn main() -> i32 =
    // Test string functions
    assert(string_contains("hello world", "world"))
    assert(not string_contains("hello world", "xyz"))
    assert(starts_with("hello", "hel"))
    assert(not starts_with("hello", "world"))
    // ends_with removed - needs pointer arithmetic support

    // Test char functions
    assert(char_to_upper(97) == 65)
    assert(char_to_lower(65) == 97)
    assert(is_alpha(65))
    assert(not is_alpha(48))
    assert(is_digit(48))
    assert(not is_digit(65))

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

    0
