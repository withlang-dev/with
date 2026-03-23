//! expect-stdout: ok

// Behavior test: match expressions
// Tests: int match, string match, wildcard, match as expression

fn describe_int(n: i32) -> str:
    match n
        0 => "zero"
        1 => "one"
        2 => "two"
        _ => "many"

fn test_match_int:
    assert(describe_int(0) == "zero")
    assert(describe_int(1) == "one")
    assert(describe_int(2) == "two")
    assert(describe_int(42) == "many")
    assert(describe_int(-1) == "many")

fn test_match_wildcard:
    let x = 99
    let result = match x
        _ => "caught"
    assert(result == "caught")

fn test_match_bool:
    let b = true
    let result = match b
        true => "yes"
        false => "no"
    assert(result == "yes")

    let b2 = false
    let r2 = match b2
        true => "yes"
        false => "no"
    assert(r2 == "no")

fn test_match_expression:
    // match as expression that returns a value
    let x = 2
    let doubled = match x
        1 => 10
        2 => 20
        3 => 30
        _ => 0
    assert(doubled == 20)

fn test_match_nested_if:
    let x = 5
    var label = ""
    if x > 0:
        label = match x
            5 => "five"
            _ => "positive"
    else:
        label = "non-positive"
    assert(label == "five")

fn main:
    test_match_int()
    test_match_wildcard()
    test_match_bool()
    test_match_expression()
    test_match_nested_if()
    println("ok")
