//! expect-stdout: ok

// Behavior test: Result type — Ok, Err, unwrap, is_ok, is_err
// Exercises Result as a sum type with Ok/Err variants and the ?? default operator.

type MyResult = Ok(i32) | Err(str)

fn divide(a: i32, b: i32) -> MyResult:
    if b == 0:
        .Err("division by zero")
    else:
        .Ok(a / b)

fn test_ok_result:
    let r = divide(10, 2)
    let val = match r
        .Ok(v) -> v
        .Err(_) -> -1
    assert(val == 5)

fn test_err_result:
    let r = divide(10, 0)
    let val = match r
        .Ok(v) -> v
        .Err(_) -> -1
    assert(val == -1)

fn test_err_message:
    let r = divide(10, 0)
    let msg = match r
        .Ok(_) -> "success"
        .Err(e) -> e
    assert(msg == "division by zero")

fn test_multiple_ok:
    let r1 = divide(100, 10)
    let r2 = divide(42, 7)
    let v1 = match r1
        .Ok(v) -> v
        .Err(_) -> 0
    let v2 = match r2
        .Ok(v) -> v
        .Err(_) -> 0
    assert(v1 == 10)
    assert(v2 == 6)

fn try_divide(a: i32, b: i32) -> MyResult:
    let v = divide(a, b)?
    .Ok(v * 2)

fn test_try_operator:
    let r = try_divide(10, 2)
    let val = match r
        .Ok(v) -> v
        .Err(_) -> -1
    assert(val == 10)
    let r2 = try_divide(10, 0)
    let val2 = match r2
        .Ok(v) -> v
        .Err(_) -> -1
    assert(val2 == -1)

fn main:
    test_ok_result()
    test_err_result()
    test_err_message()
    test_multiple_ok()
    test_try_operator()
    println("ok")
