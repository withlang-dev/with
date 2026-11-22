//! expect-debug-alloc: leak count=0
//! expect-stdout: 16 32 7
//! expect-stdout: scope ended
// D87 (§7.3a): std.context's temp arena allocates through `&self`, so a
// function that borrows the context (`implicit &Context`) allocates from
// it, any number of times in one `with` block. The `with` scope owns the
// context: every allocation is freed once, when the scope ends.
use std.context

fn scratch(n: i32, ctx: implicit &Context) -> *i8: ctx.temp.alloc(n)

fn fill(n: i32, ctx: implicit &Context) -> i32:
    let p = scratch(n)
    unsafe *(p as *mut i32) = n
    unsafe *(p as *mut i32)

fn main:
    with active(default_context()):
        let a = fill(16)
        let b = fill(32)
        let z = ctx_zeroed()
        print(f"{a} {b} {z}")
    print("scope ended")

fn ctx_zeroed(ctx: implicit &Context) -> i32:
    let p = ctx.temp.alloc_zeroed(4, 4)
    7 + unsafe *(p as *mut i32)
