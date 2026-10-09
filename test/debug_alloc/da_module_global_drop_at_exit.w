//! expect-debug-alloc: leak count=0
// #777: module globals drop at process exit. The exit wrapper drops writable
// droppable globals after fibers drain, before runtime shutdown — a heap value
// parked in a global at exit must free, not leak. Covers a str global mutated
// from Drop bodies (the original repro: the FINAL value leaked), a
// runtime-initialized global List that owns heap elements, and a never-assigned
// droppable global (zeroed storage must skip its drop, not crash).
use std.builtins.print

var TRACE: str = ""
var ITEMS: List[str] = List.new()
var SPARE: str = ""

type Tag { id: str }
impl Drop for Tag:
    fn drop(move self: Self):
        TRACE = TRACE ++ self.id

fn main:
    let a = Tag { id: "a" ++ "" }
    let b = Tag { id: "b" ++ "" }
    let _ = a
    let _ = b
    ITEMS.push("x" ++ "")
    ITEMS.push("y" ++ "")
    print(TRACE)
