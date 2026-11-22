//! expect-stdout: ok

// #589: comptime T.implements(Trait) works for generic-instantiation
// receivers that were never instantiated anywhere else in the program —
// the receiver's type is CREATED on demand, not looked up (§17.2). The
// Send answers are semantic: Rc is not Send, so nothing wrapping it is.

use std.rc

fn main:
    assert(comptime Arc[i32].implements(Send))
    assert(not comptime Rc[i32].implements(Send))
    assert(not comptime Arc[Rc[i32]].implements(Send))
    assert(comptime List[List[i32]].implements(Send))
    print("ok")
