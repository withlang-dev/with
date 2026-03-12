//! expect-stdout: ok

fn divide(a: i32, b: i32) -> Result[i32, str]:
    if b == 0:
        .Err("division by zero")
    else:
        .Ok(a / b)

fn test_ok:
    let r = divide(10, 2)
    let val = match r
        .Ok(v) => v
        .Err(_) => -1
    assert(val == 5)

fn test_err:
    let r = divide(10, 0)
    let val = match r
        .Ok(v) => v
        .Err(_) => -1
    assert(val == -1)

fn test_err_message:
    let r = divide(10, 0)
    let msg = match r
        .Ok(_) => "success"
        .Err(e) => e
    assert(msg == "division by zero")

fn main:
    test_ok()
    test_err()
    test_err_message()
    print("ok")
