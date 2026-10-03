//! expect-check-fail: use of moved value
// D87 (§7.3a, §3.8): a non-Copy `implicit Ctx` is passed explicitly, and an
// explicit argument to a plain `T` parameter moves it; a later use of the
// binding is the ordinary use of a moved value.
type Ctx { name: str }

fn take(x: i32, ctx: implicit Ctx) -> i32: x + ctx.name.len() as i32

fn main:
    with c(Ctx { name: "abc".clone() }):
        let a = take(1, ctx: c)
        let b = take(2, ctx: c)
        print(f"{a} {b}")
