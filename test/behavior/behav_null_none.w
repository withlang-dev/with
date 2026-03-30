//! expect-stdout: ok

// Tests: None value, Option[T] with None, null pointer patterns,
//        Option as function return, nested Option checks

fn test_none_basic:
    let x: Option[i32] = None
    let is_none = match x
        Some(_) => false
        None => true
    assert(is_none)

fn test_some_basic:
    let x: Option[i32] = Some(42)
    let is_some = match x
        Some(_) => true
        None => false
    assert(is_some)

fn test_none_unwrap_or:
    let x: Option[i32] = None
    let val = match x
        Some(v) => v
        None => -1
    assert(val == -1)

fn find_index(arr: [i32; 5], target: i32) -> Option[i32]:
    var i = 0
    while i < 5:
        if arr[i] == target:
            return Some(i)
        i = i + 1
    None

fn test_option_find:
    let arr = [10, 20, 30, 40, 50]
    let r1 = find_index(arr, 30)
    assert(r1.unwrap() == 2)

    let r2 = find_index(arr, 99)
    let found = match r2
        Some(_) => true
        None => false
    assert(not found)

fn safe_div(a: i32, b: i32) -> Option[i32]:
    if b == 0:
        return None
    Some(a / b)

fn test_option_safe_div:
    let r1 = safe_div(10, 2)
    assert(r1.unwrap() == 5)
    let r2 = safe_div(10, 0)
    let is_none = match r2
        Some(_) => false
        None => true
    assert(is_none)

fn test_option_chain:
    let a = safe_div(100, 10)
    // If a is Some, divide again
    let result = match a
        Some(v) => match safe_div(v, 2)
            Some(v2) => v2
            None => -1
        None => -1
    assert(result == 5)

fn test_option_multiple_returns:
    // Test function that can return None at multiple points
    assert(safe_div(10, 0).is_none())
    assert(not safe_div(10, 2).is_none())

fn main:
    test_none_basic()
    test_some_basic()
    test_none_unwrap_or()
    test_option_find()
    test_option_safe_div()
    test_option_chain()
    test_option_multiple_returns()
    print("ok")
