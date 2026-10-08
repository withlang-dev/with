//! expect-debug-alloc: leak count=0
//! expect-stdout: hello
//! expect-stdout: kept

// D86 (§18.2, #1864): a move inside a passing precondition's message is a
// conditional move on a path that does not return: the heap value stays
// owned by its binding, is freed once at scope end, and is never freed by
// the message that did not run.
use std.testing

fn consume(s: str) -> str:
    s ++ "!"

fn main:
    let s = "hel" ++ "lo"
    require(true, consume(s))
    check(true, consume(s))
    assert(true, consume(s))
    testing.require(true, consume(s))
    print(s)
    let t = "ke" ++ "pt"
    testing.check(true, t)
    print(t)
