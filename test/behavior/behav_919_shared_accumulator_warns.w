//! expect-build-stderr: warning: `s` is appended to in this loop while `prev` holds a copy of it, so every append copies the whole text
//! expect-build-stderr: warning: `t` is appended to in this loop while `last` holds a copy of it
//! expect-build-stderr: warning: string concatenation with ++ inside a loop repeatedly copies the accumulator; append to it instead
//! expect-stdout: xxx xx xxx xxx

// D219 (#919): `s = s ++ piece` appends in place while `s` is the only
// holder of its text. A variable that takes a copy on every pass shares
// it at the next append, which then copies the whole text (measured:
// 20,000 passes 15 ms, 40,000 passes 54 ms). Both orders warn. The
// prepend keeps its warning, with advice that names no builder.
fn main:
    var s = ""
    var prev = ""
    for i in 0..3:
        prev = s
        s = s ++ "x"
    var t = ""
    var last = ""
    for i in 0..3:
        t = t ++ "x"
        last = t
    var p = ""
    for i in 0..3: p = "x" ++ p
    print(f"{s} {prev} {last} {p}")
