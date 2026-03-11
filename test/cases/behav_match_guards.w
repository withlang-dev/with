//! expect-stdout: ok

// Behavior test: match guards (if conditions on arms)

fn classify(x: i32) -> str:
    match x
        n if n > 0 -> "positive"
        n if n < 0 -> "negative"
        _ -> "zero"

fn test_basic_guards:
    assert(classify(5) == "positive")
    assert(classify(-3) == "negative")
    assert(classify(0) == "zero")

fn abs_val(x: i32) -> i32:
    match x
        n if n < 0 -> 0 - n
        n -> n

fn test_guard_with_binding:
    assert(abs_val(-10) == 10)
    assert(abs_val(7) == 7)
    assert(abs_val(0) == 0)

fn test_guard_fallthrough:
    // When guard fails, should fall to next arm
    let x = 42
    let r = match x
        n if n > 100 -> "big"
        n if n > 10 -> "medium"
        _ -> "small"
    assert(r == "medium")

fn main:
    test_basic_guards()
    test_guard_with_binding()
    test_guard_fallthrough()
    println("ok")
