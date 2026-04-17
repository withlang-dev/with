//! expect-stdout: ok

// Tests: Result type, Ok/Err construction, match on Result,
//        unwrap, error propagation patterns

error MyError =
    | NotFound
    | InvalidInput

fn succeed() -> Result[i32, MyError]:
    Ok(42)

fn fail_not_found() -> Result[i32, MyError]:
    Err(.NotFound)

fn fail_invalid() -> Result[i32, MyError]:
    Err(.InvalidInput)

fn test_result_ok:
    let r = succeed()
    let val = match r:
        Ok(v) => v
        Err(_) => -1
    assert(val == 42)

fn test_result_err:
    let r = fail_not_found()
    let val = match r:
        Ok(v) => v
        Err(_) => -1
    assert(val == -1)

fn test_result_unwrap:
    let val = succeed().unwrap()
    assert(val == 42)

fn test_result_match_variants:
    let r1 = fail_not_found()
    let is_not_found = match r1:
        Err(.NotFound) => true
        _ => false
    assert(is_not_found)

    let r2 = fail_invalid()
    let is_invalid = match r2:
        Err(.InvalidInput) => true
        _ => false
    assert(is_invalid)

fn double_if_positive(x: i32) -> Result[i32, MyError]:
    if x < 0:
        return Err(.InvalidInput)
    Ok(x * 2)

fn test_conditional_result:
    let r1 = double_if_positive(5)
    assert(r1.unwrap() == 10)
    let r2 = double_if_positive(-1)
    let val = match r2:
        Ok(_) => false
        Err(.InvalidInput) => true
        Err(_) => false
    assert(val)

fn main:
    test_result_ok()
    test_result_err()
    test_result_unwrap()
    test_result_match_variants()
    test_conditional_result()
    print("ok")
