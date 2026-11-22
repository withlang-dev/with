//! expect-stdout: ok
// §13: errdefer does NOT run when a block exits via goto without an error.
var TRACE: str = ""
fn f -> Result[i32, str]:
    'body:
        defer: TRACE = TRACE ++ "D"
        errdefer: TRACE = TRACE ++ "E"
        goto 'exit
    'exit:
        Ok(0)
fn main:
    let _ = f()
    assert(TRACE == "D")
    print("ok")
