//! expect-stdout: ok

// Behavior test: match expressions with various patterns
// Tests: int match, wildcard, bool match, enum match, range patterns

type Color = Red | Green | Blue

fn test_match_int:
    let n = 2
    let result = match n
        0 -> "zero"
        1 -> "one"
        2 -> "two"
        _ -> "many"
    assert(result == "two")
    let r2 = match 99
        0 -> "zero"
        _ -> "many"
    assert(r2 == "many")

fn test_match_bool:
    let b = true
    let result = match b
        true -> "yes"
        false -> "no"
    assert(result == "yes")

fn test_match_enum:
    let c: Color = .Green
    let name = match c
        .Red -> "red"
        .Green -> "green"
        .Blue -> "blue"
    assert(name == "green")

fn test_match_range:
    let x = 5
    let label = match x
        0 -> "zero"
        1..=3 -> "small"
        4..=6 -> "medium"
        _ -> "large"
    assert(label == "medium")

fn test_match_expression:
    let x = 2
    let doubled = match x
        1 -> 10
        2 -> 20
        3 -> 30
        _ -> 0
    assert(doubled == 20)

fn main:
    test_match_int()
    test_match_bool()
    test_match_enum()
    test_match_range()
    test_match_expression()
    println("ok")
