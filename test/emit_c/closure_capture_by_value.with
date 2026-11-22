//! expect-stdout: 2
//! expect-stdout: 5
//! expect-stdout: abc!
//! expect-stdout: 2 2

// #1766, D62 (§12.4): `move ||` owns its environment. A Copy snapshot rides
// in the context word; a non-Copy capture (a str) lives in an owned cell.
// The outer `n` may change afterwards; the closure keeps its snapshot.
fn main:
    var n = 1
    let snap = move () => n + 1
    n = 5
    print(snap())
    print(n)
    let s = "abc"
    let shout = move () => s ++ "!"
    print(shout())
    var a = 1
    var b = 1
    let sum = move () => a + b
    a = 9
    b = 9
    print(f"{sum()} {sum()}")
