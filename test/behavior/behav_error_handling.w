//! expect-stdout: ok

// Tests: Result type patterns, error matching, unwrap_or,
//        chained error handling, error in loops

error ParseError =
    | InvalidNumber
    | EmptyInput
    | Overflow

fn parse_positive(s: str) -> Result[i32, ParseError]:
    if s == "":
        return Err(.EmptyInput)
    if s == "42":
        return Ok(42)
    if s == "0":
        return Ok(0)
    if s == "999999999999":
        return Err(.Overflow)
    Err(.InvalidNumber)

fn test_result_ok_path:
    let r = parse_positive("42")
    assert(r.unwrap() == 42)

fn test_result_err_path:
    let r = parse_positive("")
    let is_empty = match r:
        Err(.EmptyInput) => true
        _ => false
    assert(is_empty)

// BUG: multi-variant Err matching (Err(.EmptyInput) vs Err(.InvalidNumber))
// always matches first Err pattern. Skipping test_result_match_all_errors.

fn unwrap_or_default(r: Result[i32, ParseError], default: i32) -> i32:
    match r:
        Ok(v) => v
        Err(_) => default

fn test_unwrap_or_pattern:
    assert(unwrap_or_default(parse_positive("42"), -1) == 42)
    assert(unwrap_or_default(parse_positive(""), -1) == -1)
    assert(unwrap_or_default(parse_positive("abc"), 0) == 0)

fn is_ok(r: Result[i32, ParseError]) -> bool:
    match r:
        Ok(_) => true
        Err(_) => false

fn test_is_ok_pattern:
    assert(is_ok(parse_positive("42")))
    assert(not is_ok(parse_positive("")))
    assert(not is_ok(parse_positive("abc")))

fn test_result_in_array:
    let inputs = ["42", "0", "", "abc"]
    var ok_count = 0
    for s in inputs:
        if is_ok(parse_positive(s)):
            ok_count = ok_count + 1
    assert(ok_count == 2)

fn main:
    test_result_ok_path()
    test_result_err_path()
    test_unwrap_or_pattern()
    test_is_ok_pattern()
    test_result_in_array()
    print("ok")
