//! expect-stdout: ok

// Behavior test: combined pattern matching features

fn at_range(n: i32) -> i32:
    match n:
        x @ 1..=10 => x * 2
        _ => -1

fn or_range(n: i32) -> str:
    match n:
        0 => "zero"
        1..5 | 10..15 => "low"
        _ => "other"

fn neg_range(n: i32) -> str:
    match n:
        -100..0 => "negative"
        0 => "zero"
        1..=100 => "positive"
        _ => "huge"

fn main:
    // @ binding with range
    assert(at_range(5) == 10)
    assert(at_range(10) == 20)
    assert(at_range(11) == -1)

    // negative range patterns
    assert(neg_range(-50) == "negative")
    assert(neg_range(-1) == "negative")
    assert(neg_range(0) == "zero")
    assert(neg_range(1) == "positive")
    assert(neg_range(100) == "positive")
    assert(neg_range(101) == "huge")
    print("ok")
