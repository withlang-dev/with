//! expect-stdout: all inline match tests passed

fn main:
    test_basic()
    test_expression()
    test_trailing_comma()
    test_or_pattern()
    test_guard()
    test_wildcard()
    print("all inline match tests passed")

fn test_basic:
    let x = match 1 { 0 => "zero", 1 => "one", _ => "other" }
    assert(x == "one")

fn test_expression:
    let val = 42
    let result = match val { 0 => "empty", _ => "has value" }
    assert(result == "has value")

fn test_trailing_comma:
    let x = match 2 { 1 => "a", 2 => "b", _ => "c", }
    assert(x == "b")

fn test_or_pattern:
    let day = 6
    let kind = match day { 1 | 2 | 3 | 4 | 5 => "weekday", 6 | 7 => "weekend", _ => "invalid" }
    assert(kind == "weekend")

fn test_guard:
    let n = 15
    let label = match n { x if x > 10 => "big", _ => "small" }
    assert(label == "big")

fn test_wildcard:
    let x = match 999 { 0 => "zero", _ => "nonzero" }
    assert(x == "nonzero")
