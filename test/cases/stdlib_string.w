// Test: std.string import
use std.string

fn main() -> i32 =
    let s = "hello world"

    // string_len
    assert(string_len(s) == 11)

    // string_eq
    assert(string_eq("abc", "abc"))
    assert(not string_eq("abc", "xyz"))

    // string_to_int
    assert(string_to_int("42") == 42)
    assert(string_to_int("0") == 0)

    // is_alpha / is_digit
    assert(is_alpha(65))
    assert(not is_alpha(48))
    assert(is_digit(48))
    assert(not is_digit(65))

    println("all stdlib string tests passed")
    0
