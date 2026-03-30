//! expect-stdout: ok

// Behavior test: operator overloading
// Tests: built-in operators on primitive types, arithmetic operations

fn test_arithmetic_ops:
    assert(1 + 2 == 3)
    assert(10 - 3 == 7)
    assert(4 * 5 == 20)
    assert(10 / 2 == 5)
    assert(7 % 3 == 1)

fn test_comparison_ops:
    assert(1 < 2)
    assert(2 > 1)
    assert(1 <= 1)
    assert(1 <= 2)
    assert(2 >= 2)
    assert(3 >= 1)
    assert(5 == 5)
    assert(5 != 6)

fn test_bool_ops:
    assert(true and true)
    assert(not (true and false))
    assert(true or false)
    assert(not (false or false))

fn test_string_concat:
    let a = "hello"
    let b = " world"
    assert(a ++ b == "hello world")

fn main:
    test_arithmetic_ops()
    test_comparison_ops()
    test_bool_ops()
    test_string_concat()
    print("ok")
