//! expect-stdout: ok

// Tests: string literals, string comparison, string concatenation,
//        string length, string in function args/returns

fn test_string_literal:
    let s = "hello"
    assert(s == "hello")

fn test_string_comparison:
    assert("abc" == "abc")
    assert("abc" != "def")
    assert("" == "")
    assert("a" != "")

fn test_string_concat:
    let a = "hello"
    let b = " world"
    let c = a ++ b
    assert(c == "hello world")

fn test_string_concat_empty:
    let a = "hello"
    let b = ""
    assert(a ++ b == "hello")
    assert(b ++ a == "hello")

fn greet(name: str) -> str:
    "hello " ++ name

fn test_string_in_function:
    assert(greet("world") == "hello world")
    assert(greet("Alice") == "hello Alice")

fn test_string_multi_concat:
    let s = "a" ++ "b" ++ "c" ++ "d"
    assert(s == "abcd")

fn test_string_length:
    let s = "hello"
    assert(s.len() == 5)
    assert("".len() == 0)
    assert("a".len() == 1)

fn choose_string(flag: bool) -> str:
    if flag: "yes" else: "no"

fn test_string_from_condition:
    assert(choose_string(true) == "yes")
    assert(choose_string(false) == "no")

fn test_string_in_match:
    let result = match 1
        1 => "one"
        2 => "two"
        _ => "other"
    assert(result == "one")

fn main:
    test_string_literal()
    test_string_comparison()
    test_string_concat()
    test_string_concat_empty()
    test_string_in_function()
    test_string_multi_concat()
    test_string_length()
    test_string_from_condition()
    test_string_in_match()
    println("ok")
