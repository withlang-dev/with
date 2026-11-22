//! expect-stdout: ok
// §9: a default argument expression is evaluated at each call site where the
// argument is omitted, not once.
var COUNTER: i32 = 0
fn nextval -> i32:
    COUNTER = COUNTER + 1
    COUNTER
fn f(x: i32, y: i32 = nextval()) -> i32:
    x + y
fn main:
    let a = f(100)
    let b = f(100)
    assert(a == 101)
    assert(b == 102)
    print("ok")
