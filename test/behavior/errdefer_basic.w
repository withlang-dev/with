//! expect-stdout: cleanup-on-error

enum MyResult { Ok(i32) | Err(str) }

fn might_fail(x: i32) -> MyResult:
    if x < 0:
        .Err("negative")
    else:
        .Ok(x * 2)

fn test_errdefer_on_error() -> MyResult:
    errdefer: print("cleanup-on-error")
    let val = might_fail(-1)?
    .Ok(val)

fn test_errdefer_on_success() -> MyResult:
    errdefer: print("should-not-run")
    let val = might_fail(5)?
    .Ok(val)

fn main:
    // errdefer should run when ? propagates error
    let r1 = test_errdefer_on_error()
    // errdefer should NOT run on success
    let r2 = test_errdefer_on_success()
