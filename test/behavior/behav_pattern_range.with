//! expect-stdout: ok

// Behavior test: range patterns in match expressions

fn classify(n: i32) -> str:
    match n:
        0 => "zero"
        1..5 => "small"
        5..=10 => "medium"
        _ => "large"

fn classify_signed(n: i32) -> str:
    match n:
        -10..0 => "negative"
        0 => "zero"
        1..=100 => "positive"
        _ => "other"

fn main:
    assert(classify(0) == "zero")
    assert(classify(1) == "small")
    assert(classify(3) == "small")
    assert(classify(4) == "small")
    assert(classify(5) == "medium")
    assert(classify(7) == "medium")
    assert(classify(10) == "medium")
    assert(classify(11) == "large")
    assert(classify_signed(-5) == "negative")
    assert(classify_signed(-10) == "negative")
    assert(classify_signed(0) == "zero")
    assert(classify_signed(50) == "positive")
    assert(classify_signed(100) == "positive")
    assert(classify_signed(101) == "other")
    print("ok")
