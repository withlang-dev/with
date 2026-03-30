//! expect-stdout: ok

// End-to-end test: string operations
// Tests: string literals, concatenation (++), len(), comparisons

fn test_string_literal:
    let s = "hello"
    assert(s == "hello")

fn test_string_concat:
    let a = "hello"
    let b = " world"
    let c = a ++ b
    assert(c == "hello world")

fn test_string_len:
    assert("".len() == 0)
    assert("a".len() == 1)
    assert("hello".len() == 5)

fn test_string_comparison:
    assert("abc" == "abc")
    assert("abc" != "def")
    assert("a" != "b")

fn test_string_concat_chain:
    let result = "a" ++ "b" ++ "c"
    assert(result == "abc")

fn test_string_with_numbers:
    let label = "count: " ++ int_to_string(42)
    assert(label == "count: 42")

fn test_empty_string:
    let empty = ""
    assert(empty.len() == 0)
    let nonempty = empty ++ "x"
    assert(nonempty == "x")

fn main:
    test_string_literal()
    test_string_concat()
    test_string_len()
    test_string_comparison()
    test_string_concat_chain()
    test_string_with_numbers()
    test_empty_string()
    print("ok")
