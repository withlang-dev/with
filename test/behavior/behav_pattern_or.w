//! expect-stdout: ok

// Behavior test: or-patterns in match expressions

fn classify(n: i32) -> str:
    match n:
        1 | 2 | 3 => "small"
        4 | 5 | 6 => "medium"
        _ => "large"

fn main:
    assert(classify(1) == "small")
    assert(classify(2) == "small")
    assert(classify(3) == "small")
    assert(classify(4) == "medium")
    assert(classify(5) == "medium")
    assert(classify(6) == "medium")
    assert(classify(7) == "large")
    print("ok")
