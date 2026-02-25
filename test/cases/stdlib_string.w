// Test: std.string import
use std.string

fn main() -> i32 =
    let s = "hello world"

    // string_len
    assert(string_len(s) == 11)

    // string_eq
    assert(string_eq("abc", "abc"))
    assert(not string_eq("abc", "xyz"))

    // string_contains
    assert(string_contains(s, "world"))
    assert(not string_contains(s, "xyz"))

    // starts_with
    assert(starts_with(s, "hello"))
    assert(not starts_with(s, "world"))

    // string_to_int
    assert(string_to_int("42") == 42)
    assert(string_to_int("0") == 0)

    println("all stdlib string tests passed")
    0
