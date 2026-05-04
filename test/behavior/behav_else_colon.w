//! expect-stdout: ok

// Behavior test: else: colon form (bare else: blocks)
// Tests: else: with block body, else: in if/else: if/else: chains

fn classify(n: i32) -> str:
    if n > 0:
        "positive"
    else if n < 0:
        "negative"
    else:
        "zero"

fn test_if_else_chain:
    assert(classify(5) == "positive")
    assert(classify(-3) == "negative")
    assert(classify(0) == "zero")

fn test_else_block:
    let x = 10
    var result = ""
    if x > 100:
        result = "big"
    else:
        result = "small"
    assert(result == "small")

fn test_nested_if_else:
    let a = 3
    let b = 7
    var msg = ""
    if a > b:
        msg = "a wins"
    else if a == b:
        msg = "tie"
    else:
        if b > 5:
            msg = "b is big"
        else:
            msg = "b is small"
    assert(msg == "b is big")

fn main:
    test_if_else_chain()
    test_else_block()
    test_nested_if_else()
    print("ok")
