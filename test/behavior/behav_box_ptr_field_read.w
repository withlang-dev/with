//! expect-stdout: local 7
//! expect-stdout: arg 7
//! expect-stdout: drop 9
//! expect-stdout: drop-arg 9

// #1280: `Box[T].ptr` is an ordinary field read of a `*mut T` (§1; a raw
// pointer is Copy, §2.2). The transparent Box lowering made the field GEP
// land on the payload's first field: `b.ptr` read `Cell.a` as an i32 and
// trapped at run time on a local; handed straight to a `*mut Cell`
// parameter inside `move fn drop()` it failed codegen
// (`wrong argument type actual=i32 expected=ptr`).
use std.box.Box

type Cell { a: i32 }

unsafe fn peek(p: *mut Cell) -> i32: (*p).a

type W { repr: Box[Cell] }

impl Drop for W:
    move fn drop():
        let p = self.repr.ptr
        print(f"drop {unsafe { (*p).a }}")
        print(f"drop-arg {unsafe { peek(self.repr.ptr) }}")

fn main:
    let b = Box.new(Cell { a: 7 })
    let p = b.ptr
    print(f"local {unsafe { (*p).a }}")
    print(f"arg {unsafe { peek(b.ptr) }}")
    let w = W { repr: Box.new(Cell { a: 9 }) }
    drop(w)
