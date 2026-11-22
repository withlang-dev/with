//! expect-stdout: errdefer-2errdefer-1defer-2defer-1done

enum MyResult { Ok(i32) | Err(str) }

fn fail() -> MyResult:
    .Err("oops")

fn test_ordering() -> MyResult:
    defer: write("defer-1")
    errdefer: write("errdefer-1")
    defer: write("defer-2")
    errdefer: write("errdefer-2")
    let val = fail()?
    .Ok(val)

fn main:
    let r = test_ordering()
    write("done")
