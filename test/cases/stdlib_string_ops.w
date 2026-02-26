// Test std string library operations
use std.string

fn main() -> i32 =
    assert(string_eq("hello", "hello"))
    assert(not string_eq("hello", "world"))
    assert(string_cmp("abc", "abc") == 0)
    assert(string_len("test") == 4)
    assert(is_alpha(65))
    assert(is_digit(48))
    assert(is_space(32))
    println("stdlib string tests passed")
    0
