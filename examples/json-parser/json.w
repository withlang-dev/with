// ===================================================================
// JSON-like Parser — Simplified
//
// Demonstrates:
//   - Enum variants
//   - Pattern matching
//   - Recursive functions
//   - String interpolation
//   - For loops and ranges
// ===================================================================

type JsonTag = Null | Bool | Number | Str

fn classify_char(ch: i32) -> i32:
    if ch == 123 then 1
    else if ch == 125 then 2
    else if ch == 91 then 3
    else if ch == 93 then 4
    else if ch == 58 then 5
    else if ch == 44 then 6
    else 0

fn update_depth(depth: i32, cls: i32) -> i32:
    if cls == 1 or cls == 3 then depth + 1
    else if cls == 2 or cls == 4 then depth - 1
    else depth

fn max(a: i32, b: i32) -> i32:
    if a > b then a else b

fn count_depth(input: [10]i32, len: i32) -> i32:
    var max_depth = 0
    var depth = 0
    for i in 0..len:
        let cls = classify_char(input[i])
        depth = update_depth(depth, cls)
        max_depth = max(max_depth, depth)
    max_depth

fn is_digit(ch: i32) -> bool:
    ch >= 48 and ch <= 57

fn classify_value(first_char: i32) -> i32:
    if first_char == 110 then 0
    else if first_char == 116 then 1
    else if first_char == 102 then 2
    else if is_digit(first_char) then 3
    else if first_char == 34 then 4
    else 5

fn is_json_char(ch: i32) -> bool:
    let cls = classify_char(ch)
    cls > 0 or is_digit(ch) or ch == 34 or ch == 32

fn fib(n: i32) -> i32:
    if n <= 1 then n
    else fib(n - 1) + fib(n - 2)

fn main -> i32:
    println("=== JSON Parser Demo ===")

    let input: [10]i32 = [123, 34, 107, 101, 121, 34, 58, 52, 50, 125]

    let depth = count_depth(input, 10)
    println("Max nesting depth: {depth}")

    var valid_count = 0
    for i in 0..10:
        if is_json_char(input[i]) then valid_count = valid_count + 1 else valid_count = valid_count
    println("Valid JSON chars: {valid_count}/10")

    let null_type = classify_value(110)
    let true_type = classify_value(116)
    let num_type = classify_value(52)
    let str_type = classify_value(34)
    println("null=type{null_type}, true=type{true_type}, num=type{num_type}, str=type{str_type}")

    let tag = Null
    match tag
        Null -> println("Got null value")
        Bool -> println("Got bool")
        Number -> println("Got number")
        Str -> println("Got string")

    let tag2 = Number
    match tag2
        Null -> println("null")
        Number -> println("Got a number value")
        _ -> println("other")

    let f10 = fib(10)
    println("fib(10) = {f10}")

    println("=== Demo complete ===")
