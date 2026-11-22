//! expect-stdout: ok

// Tests: pointer deref, variable mutation, global variables, struct inside fn,
//        function returns, double cast, const expressions, nested blocks,
//        pass by reference, string return, arithmetic basics

var g_counter: i32 = 0

fn test_global_variables:
    assert(g_counter == 0)
    g_counter = 1234
    assert(g_counter == 1234)
    g_counter = 0

fn test_pointer_deref:
    var x: i32 = 3
    let y = &raw mut x
    unsafe *y = unsafe *y + 1
    assert(x == 4)

fn test_variable_mutation:
    var x = 10
    x = x + 5
    assert(x == 15)
    x = x * 2
    assert(x == 30)

fn test_const_binding:
    let x = 42
    assert(x == 42)
    let y = x + 8
    assert(y == 50)

fn test_arithmetic_basics:
    assert(2 + 3 == 5)
    assert(10 - 7 == 3)
    assert(4 * 5 == 20)
    assert(20 / 4 == 5)
    assert(17 % 5 == 2)

fn test_comparison_ops:
    assert(1 < 2)
    assert(2 > 1)
    assert(3 <= 3)
    assert(3 >= 3)
    assert(5 <= 6)
    assert(6 >= 5)
    assert(1 != 2)
    assert(3 == 3)

fn test_unary_ops:
    let a = 5
    let b = -a
    assert(b == -5)
    assert(not false)
    assert(not not true)

fn add(a: i32, b: i32) -> i32:
    a + b

fn mul(a: i32, b: i32) -> i32:
    a * b

fn test_fn_calls:
    assert(add(3, 4) == 7)
    assert(mul(5, 6) == 30)
    assert(add(mul(2, 3), 4) == 10)

fn identity(x: i32) -> i32:
    x

fn test_fn_return:
    assert(identity(42) == 42)
    assert(identity(-1) == -1)

fn return_wider(x: i32) -> i64:
    x as i64

fn test_implicit_widen_return:
    let r = return_wider(1234)
    assert(r == 1234i64)

fn test_nested_blocks:
    var x = 1
    if true:
        var y = 2
        x = x + y
    assert(x == 3)

fn test_nested_if:
    var result = 0
    if true:
        if true:
            result = 42
    assert(result == 42)

fn test_while_loop:
    var sum = 0
    var i = 1
    while i <= 10:
        sum = sum + i
        i = i + 1
    assert(sum == 55)

fn test_while_break:
    var i = 0
    while true:
        if i == 5:
            break
        i = i + 1
    assert(i == 5)

fn test_while_continue:
    var sum = 0
    var i = 0
    while i < 10:
        i = i + 1
        if i % 2 == 0:
            continue
        sum = sum + i
    // 1+3+5+7+9 = 25
    assert(sum == 25)

fn test_for_loop:
    var sum = 0
    let arr = [1, 2, 3, 4, 5]
    for v in arr:
        sum = sum + v
    assert(sum == 15)

type Point { x: i32, y: i32 }

fn make_point(x: i32, y: i32) -> Point:
    Point { x: x, y: y }

fn test_struct_basic:
    let p = make_point(3, 4)
    assert(p.x == 3)
    assert(p.y == 4)

fn test_struct_mutation:
    var p = Point { x: 1, y: 2 }
    p.x = 10
    p.y = 20
    assert(p.x == 10)
    assert(p.y == 20)

unsafe fn inc(x: *mut i32):
    *x = *x + 1

fn test_pass_by_ptr:
    var val = 41
    unsafe { inc(&raw mut val) }
    assert(val == 42)

fn test_multiple_returns:
    assert(abs_val(5) == 5)
    assert(abs_val(-5) == 5)
    assert(abs_val(0) == 0)

fn abs_val(x: i32) -> i32:
    if x < 0:
        return -x
    x

fn test_match_basic:
    assert(describe(1) == 1)
    assert(describe(2) == 2)
    assert(describe(99) == 0)

fn describe(x: i32) -> i32:
    match x:
        1 => 1
        2 => 2
        _ => 0

fn main:
    test_global_variables()
    test_pointer_deref()
    test_variable_mutation()
    test_const_binding()
    test_arithmetic_basics()
    test_comparison_ops()
    test_unary_ops()
    test_fn_calls()
    test_fn_return()
    test_implicit_widen_return()
    test_nested_blocks()
    test_nested_if()
    test_while_loop()
    test_while_break()
    test_while_continue()
    test_for_loop()
    test_struct_basic()
    test_struct_mutation()
    test_pass_by_ptr()
    test_multiple_returns()
    test_match_basic()
    print("ok")
