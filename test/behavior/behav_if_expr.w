//! expect-stdout: ok

// Tests: if/else, else-if chains, if as expression, nested if,
//        if with comparison operators, if in function return

fn test_if_basic:
    var x = 0
    if true:
        x = 1
    assert(x == 1)

fn test_if_else:
    var x = 0
    if false:
        x = 1
    else:
        x = 2
    assert(x == 2)

fn test_else_if_chain:
    assert(classify(1) == "one")
    assert(classify(2) == "two")
    assert(classify(3) == "three")
    assert(classify(99) == "other")

fn classify(x: i32) -> str:
    if x == 1:
        return "one"
    else if x == 2:
        return "two"
    else if x == 3:
        return "three"
    else:
        return "other"

fn test_if_expression:
    let x = if true: 10 else: 20
    assert(x == 10)
    let y = if false: 10 else: 20
    assert(y == 20)

fn test_if_expression_in_call:
    let a = 5
    let b = 10
    let max_val = if a > b: a else: b
    assert(max_val == 10)

fn test_nested_if:
    var result = 0
    if true:
        if true:
            result = 1
        else:
            result = 2
    else:
        result = 3
    assert(result == 1)

fn test_nested_if_else:
    var result = 0
    if false:
        result = 1
    else:
        if true:
            result = 2
        else:
            result = 3
    assert(result == 2)

fn test_if_with_comparison:
    let a = 10
    let b = 20
    assert(a < b)
    assert(b > a)
    assert(a <= 10)
    assert(b >= 20)
    assert(a != b)
    assert(a == 10)

fn abs_val(x: i32) -> i32:
    if x < 0: -x else: x

fn test_if_in_return:
    assert(abs_val(5) == 5)
    assert(abs_val(-5) == 5)
    assert(abs_val(0) == 0)

fn max(a: i32, b: i32) -> i32:
    if a > b: a else: b

fn min(a: i32, b: i32) -> i32:
    if a < b: a else: b

fn test_if_helper_fns:
    assert(max(3, 7) == 7)
    assert(max(10, 2) == 10)
    assert(min(3, 7) == 3)
    assert(min(10, 2) == 2)

fn main:
    test_if_basic()
    test_if_else()
    test_else_if_chain()
    test_if_expression()
    test_if_expression_in_call()
    test_nested_if()
    test_nested_if_else()
    test_if_with_comparison()
    test_if_in_return()
    test_if_helper_fns()
    println("ok")
