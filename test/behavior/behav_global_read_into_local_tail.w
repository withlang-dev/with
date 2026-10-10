//! expect-stdout: ok

// #643: reading a plain top-level global (var or let, no annotation) into an
// unannotated local must not drop the function's implicit tail-expression
// value. The global's type was left unresolved, propagated to the local, and
// the tail was dropped as a type mismatch (returned the default).
var GV: i32 = 7
let GL: i32 = 10

fn from_var() -> i32:
    let mid = GV
    mid + 5

fn from_let() -> i32:
    let mid = GL
    mid + 2

fn main:
    assert(from_var() == 12)
    assert(from_let() == 12)
    print("ok")
