//! expect-stdout: ok

// End-to-end test: if/else expressions
// Tests: if/else, nested if, if as expression, if without else

fn test_basic_if:
    let x = 10
    if x > 5:
        assert(true)
    else:
        assert(false)

fn test_if_else_expression:
    let x = 3
    let result = if x > 0 then 1 else -1
    assert(result == 1)
    let result2 = if x < 0 then 1 else -1
    assert(result2 == -1)

fn test_nested_if:
    let x = 15
    if x > 10:
        if x > 20:
            assert(false)
        else:
            assert(true)
    else:
        assert(false)

fn test_if_else_chain:
    let x = 5
    let label = if x < 0 then "negative" else if x == 0 then "zero" else "positive"
    assert(label == "positive")

fn classify(n: i32) -> str:
    if n < 0:
        "negative"
    else if n == 0:
        "zero"
    else:
        "positive"

fn test_if_in_function:
    assert(classify(-5) == "negative")
    assert(classify(0) == "zero")
    assert(classify(42) == "positive")

fn test_if_bool_conditions:
    let a = true
    let b = false
    if a:
        assert(true)
    if b:
        assert(false)
    if not b:
        assert(true)

fn main:
    test_basic_if()
    test_if_else_expression()
    test_nested_if()
    test_if_else_chain()
    test_if_in_function()
    test_if_bool_conditions()
    println("ok")
