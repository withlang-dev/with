// Tests for the JSON parser example

use test.testing

type JsonTag = Null | Bool | Number | Str

fn classify_char(ch: i32) -> i32:
    match ch
        123 -> 1   // {
        125 -> 2   // }
        91  -> 3   // [
        93  -> 4   // ]
        58  -> 5   // :
        44  -> 6   // ,
        _   -> 0

fn update_depth(depth: i32, cls: i32) -> i32:
    if cls in [1, 3] then depth + 1
    else if cls in [2, 4] then depth - 1
    else depth

fn max(a: i32, b: i32) -> i32: if a > b then a else b

fn count_depth(input: [10]i32, len: i32) -> i32:
    var max_depth = 0
    var depth = 0
    for i in 0..len:
        let cls = classify_char(input[i])
        depth = update_depth(depth, cls)
        max_depth = max(max_depth, depth)
    max_depth

fn is_digit(ch: i32) -> bool: ch in 48..=57

fn classify_value(first_char: i32) -> i32:
    if first_char == 110 then 0
    else if first_char == 116 then 1
    else if first_char == 102 then 2
    else if is_digit(first_char) then 3
    else if first_char == 34 then 4
    else 5

fn is_json_char(ch: i32) -> bool:
    let cls = classify_char(ch)
    cls > 0 or is_digit(ch) or ch in [34, 32]

fn fib(n: i32) -> i32:
    if n <= 1 then n
    else fib(n - 1) + fib(n - 2)

fn tag_to_int(t: JsonTag) -> i32:
    match t
        Null -> 0
        Bool -> 1
        Number -> 2
        Str -> 3

@[test]
fn test_json_parser_example:
    // Test classify_char
    assert_true(classify_char(123) == 1)
    assert_true(classify_char(125) == 2)
    assert_true(classify_char(91) == 3)
    assert_true(classify_char(93) == 4)
    assert_true(classify_char(58) == 5)
    assert_true(classify_char(44) == 6)
    assert_true(classify_char(65) == 0)

    // Test update_depth
    assert_true(update_depth(0, 1) == 1)
    assert_true(update_depth(1, 2) == 0)
    assert_true(update_depth(2, 3) == 3)
    assert_true(update_depth(3, 4) == 2)
    assert_true(update_depth(5, 0) == 5)

    // Test count_depth: { "key": 42 }
    let input: [10]i32 = [123, 34, 107, 101, 121, 34, 58, 52, 50, 125]
    assert_true(count_depth(input, 10) == 1)

    // Test count_depth: nested { [ ] }
    let nested: [10]i32 = [123, 91, 91, 93, 93, 125, 0, 0, 0, 0]
    assert_true(count_depth(nested, 6) == 3)

    // Test is_digit
    assert_true(is_digit(48))
    assert_true(is_digit(57))
    assert_true(not is_digit(47))
    assert_true(not is_digit(58))

    // Test classify_value
    assert_true(classify_value(110) == 0)
    assert_true(classify_value(116) == 1)
    assert_true(classify_value(102) == 2)
    assert_true(classify_value(52) == 3)
    assert_true(classify_value(34) == 4)
    assert_true(classify_value(0) == 5)

    // Test is_json_char
    assert_true(is_json_char(123))
    assert_true(is_json_char(32))
    assert_true(is_json_char(49))
    assert_true(not is_json_char(1))

    // Test fib
    assert_true(fib(0) == 0)
    assert_true(fib(1) == 1)
    assert_true(fib(5) == 5)
    assert_true(fib(10) == 55)

    // Test enum pattern matching via helper
    assert_true(tag_to_int(Null) == 0)
    assert_true(tag_to_int(Bool) == 1)
    assert_true(tag_to_int(Number) == 2)
    assert_true(tag_to_int(Str) == 3)

