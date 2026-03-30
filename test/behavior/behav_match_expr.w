//! expect-stdout: ok

// Tests: match on integers, match on enums, match with ranges,
//        match with wildcard, match as expression, match with guards,
//        match with or-patterns, match with @ binding

fn test_match_integer:
    assert(describe_num(0) == "zero")
    assert(describe_num(1) == "one")
    assert(describe_num(2) == "two")
    assert(describe_num(99) == "other")
    assert(describe_num(-5) == "other")

fn describe_num(x: i32) -> str:
    match x
        0 => "zero"
        1 => "one"
        2 => "two"
        _ => "other"

fn test_match_range:
    assert(classify_age(0) == "baby")
    assert(classify_age(5) == "child")
    assert(classify_age(15) == "teen")
    assert(classify_age(30) == "adult")
    assert(classify_age(70) == "senior")

fn classify_age(age: i32) -> str:
    match age
        0..=2 => "baby"
        3..=12 => "child"
        13..=19 => "teen"
        20..=64 => "adult"
        _ => "senior"

enum Color { Red | Green | Blue }

fn test_match_enum:
    assert(color_name(Color.Red) == "red")
    assert(color_name(Color.Green) == "green")
    assert(color_name(Color.Blue) == "blue")

fn color_name(c: Color) -> str:
    match c
        .Red => "red"
        .Green => "green"
        .Blue => "blue"

fn test_match_expression:
    let x = 5
    let result = match x
        1 => 10
        5 => 50
        _ => 0
    assert(result == 50)

fn test_match_negative:
    assert(sign(-10) == -1)
    assert(sign(0) == 0)
    assert(sign(10) == 1)

fn sign(x: i32) -> i32:
    if x < 0:
        return -1
    else if x > 0:
        return 1
    0

fn test_match_wildcard:
    let x = 42
    var matched_wildcard = false
    match x
        0 => assert(false)
        1 => assert(false)
        _ => matched_wildcard = true
    assert(matched_wildcard)

fn test_match_guard:
    assert(abs_classify(-5) == "negative")
    assert(abs_classify(0) == "zero")
    assert(abs_classify(5) == "positive")

fn abs_classify(x: i32) -> str:
    match x
        n if n < 0 => "negative"
        n if n > 0 => "positive"
        _ => "zero"

fn test_match_or_pattern:
    assert(is_weekend(6))
    assert(is_weekend(7))
    assert(not is_weekend(1))
    assert(not is_weekend(3))

fn is_weekend(day: i32) -> bool:
    match day
        6 | 7 => true
        _ => false

fn test_match_at_binding:
    assert(double_small(3) == 6)
    assert(double_small(15) == 15)

fn double_small(x: i32) -> i32:
    match x
        n @ 1..=10 => n * 2
        _ => x

fn test_match_multiple_ranges:
    assert(http_category(200) == "success")
    assert(http_category(301) == "redirect")
    assert(http_category(404) == "client_error")
    assert(http_category(500) == "server_error")
    assert(http_category(100) == "other")

fn http_category(code: i32) -> str:
    match code
        200..=299 => "success"
        300..=399 => "redirect"
        400..=499 => "client_error"
        500..=599 => "server_error"
        _ => "other"

fn main:
    test_match_integer()
    test_match_range()
    test_match_enum()
    test_match_expression()
    test_match_negative()
    test_match_wildcard()
    test_match_guard()
    test_match_or_pattern()
    test_match_at_binding()
    test_match_multiple_ranges()
    print("ok")
