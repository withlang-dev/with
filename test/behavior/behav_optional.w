//! expect-stdout: ok

// Tests: Option type, Some/None, unwrap, match on Option,
//        Option in return, Option with different payload types

fn test_option_some:
    let x: Option[i32] = Some(42)
    assert(x.unwrap() == 42)

fn test_option_none:
    let x: Option[i32] = None
    let val = match x
        Some(v) => v
        None => -1
    assert(val == -1)

fn test_option_match:
    let a: Option[i32] = Some(10)
    let b: Option[i32] = None
    assert(unwrap_or(a, 0) == 10)
    assert(unwrap_or(b, 0) == 0)

fn unwrap_or(opt: Option[i32], default: i32) -> i32:
    match opt
        Some(v) => v
        None => default

fn find_first_positive(arr: [i32; 5]) -> Option[i32]:
    for v in arr:
        if v > 0:
            return Some(v)
    None

fn test_option_from_function:
    let arr1 = [-3, -1, 0, 5, 10]
    let result = find_first_positive(arr1)
    assert(result.unwrap() == 5)

fn test_option_none_from_function:
    let arr2 = [-3, -1, 0, -5, -10]
    let result = find_first_positive(arr2)
    let val = match result
        Some(v) => v
        None => -999
    assert(val == -999)

fn test_option_is_some:
    let a: Option[i32] = Some(1)
    let b: Option[i32] = None
    let a_has_val = match a
        Some(_) => true
        None => false
    let b_has_val = match b
        Some(_) => true
        None => false
    assert(a_has_val)
    assert(not b_has_val)

fn test_option_map_pattern:
    let x: Option[i32] = Some(5)
    // Map: transform the value inside
    let val = match x
        Some(v) => v * 2
        None => -1
    assert(val == 10)

fn test_option_chain_pattern:
    let x: Option[i32] = Some(10)
    // and_then pattern: chain optional operations
    let val = match x
        Some(v) if v > 5 => v + 100
        Some(_) => -1
        None => -1
    assert(val == 110)

fn main:
    test_option_some()
    test_option_none()
    test_option_match()
    test_option_from_function()
    test_option_none_from_function()
    test_option_is_some()
    test_option_map_pattern()
    test_option_chain_pattern()
    print("ok")
