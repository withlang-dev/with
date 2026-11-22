//! expect-stdout: ok

// Behavior test: string concatenation and int_to_string
// String interpolation (\{expr}) is not yet implemented.
// Tests concat (++) and int_to_string for equivalent behavior.

fn test_basic_concat:
    let name = "world"
    let s = "hello " ++ name
    assert(s == "hello world")

fn test_concat_int:
    let x = 42
    let s = "value is " ++ int_to_string(x)
    assert(s == "value is 42")

fn test_concat_expr:
    let a = 3
    let b = 4
    let s = "sum is " ++ int_to_string(a + b)
    assert(s == "sum is 7")

fn test_concat_multiple:
    let x = 1
    let y = 2
    let s = int_to_string(x) ++ " and " ++ int_to_string(y)
    assert(s == "1 and 2")

fn test_concat_identity:
    let v = "ok"
    let s = "" ++ v
    assert(s == "ok")

fn test_no_concat:
    let s = "plain string"
    assert(s == "plain string")

fn main:
    test_basic_concat()
    test_concat_int()
    test_concat_expr()
    test_concat_multiple()
    test_concat_identity()
    test_no_concat()
    print("ok")
