//! expect-stdout: errdefer-2errdefer-1defer-2defer-1done

enum MyResult { Ok(i32) | Err(str) }

fn fail() -> MyResult:
    .Err("oops")

fn test_ordering() -> MyResult:
    defer print("defer-1")
    errdefer print("errdefer-1")
    defer print("defer-2")
    errdefer print("errdefer-2")
    let val = fail()?
    .Ok(val)

fn main:
    let r = test_ordering()
    print("done")
