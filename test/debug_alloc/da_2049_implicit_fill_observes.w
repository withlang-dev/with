//! expect-debug-alloc: leak count=0
//! expect-stdout: 4 6
//! expect-stdout: drop ctx
//! expect-stdout: drop ctx
//! expect-stdout: took 4
//! expect-stdout: done
// #2049, D87 (§7.3a): an implicit fill observes the `with` binding and
// never consumes it. `implicit &Ctx` borrows it any number of times; a
// non-Copy `Ctx` parameter is passed explicitly, which moves the binding,
// and the callee drops it once. The fill was a `copy` of the binding into a
// consuming `implicit Ctx`: the callee and the binding's scope both dropped
// the one value (DOUBLE FREE).
type Ctx { name: str }

impl Drop for Ctx:
    move fn drop():
        print("drop ctx")

fn peek(x: i32, ctx: implicit &Ctx) -> i32: x + ctx.name.len() as i32
fn take(x: i32, ctx: Ctx) -> i32: x + ctx.name.len() as i32

fn main:
    with c(Ctx { name: "a".clone() }):
        print(f"{peek(3)} {peek(5)}")
    with c(Ctx { name: "abc".clone() }):
        let n = take(1, ctx: c)
        print(f"took {n}")
    print("done")
