//! expect-stdout: ok

// ── Option comprehensions ──

fn get_opt(x: i32) -> ?i32:
    if x > 0: .Some(x) else: .None

fn double_positive(x: i32) -> ?i32:
    if x > 0: .Some(x * 2) else: .None

fn test_option_basic:
    let result: ?i32 = [x + y for x in get_opt(5) for y in double_positive(x)]
    assert(result == .Some(15))

fn test_option_none_first:
    let result: ?i32 = [x + y for x in get_opt(-1) for y in double_positive(1)]
    assert(result == .None)

fn test_option_none_second:
    let result: ?i32 = [x + y for x in get_opt(5) for y in double_positive(-1)]
    assert(result == .None)

// ── Result comprehensions ──

fn get_result(x: i32) -> Result[i32, str]:
    if x > 0: Ok(x) else: Err("negative")

fn test_result_basic:
    let r: Result[i32, str] = [x + y for x in get_result(5) for y in get_result(x * 2)]
    match r:
        Ok(v) => assert(v == 15)
        Err(_) => assert(false)

fn test_result_err_propagation:
    let r: Result[i32, str] = [x + y for x in get_result(-1) for y in get_result(1)]
    match r:
        Ok(_) => assert(false)
        Err(e) => assert(e == "negative")

fn test_result_second_err:
    let r: Result[i32, str] = [x + y for x in get_result(5) for y in get_result(-1)]
    match r:
        Ok(_) => assert(false)
        Err(e) => assert(e == "negative")

fn main:
    test_option_basic()
    test_option_none_first()
    test_option_none_second()
    test_result_basic()
    test_result_err_propagation()
    test_result_second_err()
    print("ok")
