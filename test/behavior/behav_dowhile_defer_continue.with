//! expect-stdout: bddbdd
// §13: a `defer` in a do-while body fires every iteration, including on continue.
var TRACE: str = ""
fn f:
    var i = 0
    do:
        defer: TRACE = TRACE ++ "d"
        i += 1
        if i % 2 == 0:
            continue
        TRACE = TRACE ++ "b"
    while i < 4
fn main:
    f()
    print(TRACE)
