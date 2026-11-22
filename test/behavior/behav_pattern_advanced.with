//! expect-stdout: ok

// Behavior test: advanced pattern matching (spec SS9.7)
// Tests range patterns and wildcard patterns which are implemented.
// TODO: struct patterns, slice patterns, @ binding not yet implemented.

fn test_range_patterns:
    let n = 5
    let r = match n:
        0 => "zero"
        1..5 => "low"
        5..=10 => "mid"
        _ => "high"
    assert(r == "mid")
    let r2 = match 1:
        0 => "zero"
        1..5 => "low"
        _ => "other"
    assert(r2 == "low")
    let r3 = match 11:
        0..=10 => "in range"
        _ => "high"
    assert(r3 == "high")

fn test_wildcard_pattern:
    let x = 999
    let result = match x:
        _ => "caught"
    assert(result == "caught")

fn test_inline_or_pattern:
    let n = 2
    let r = match n:
        1 | 2 | 3 => "small"
        _ => "big"
    assert(r == "small")

fn main:
    test_range_patterns()
    test_wildcard_pattern()
    test_inline_or_pattern()
    print("ok")
