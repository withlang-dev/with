//! expect-stdout: ok

// An implicit fill is the `with` binding passed as the argument (D5, §3.8,
// §7.3a): a `&Ctx` parameter borrows the context, a plain `Ctx` parameter
// takes it, once (#2049). Borrowing fills come before the taking one.

type Ctx { multiplier: i32 }

fn by_value(x: i32, ctx: implicit Ctx) -> i32:
    x * ctx.multiplier

fn by_ref(x: i32, ctx: implicit &Ctx) -> i32:
    x * ctx.multiplier

fn combined(x: i32, ctx: implicit Ctx) -> i32:
    by_value(by_ref(x))

fn main:
    with context(Ctx { multiplier: 3 }):
        assert(by_ref(5) == 15)
        assert(by_value(4) == 12)
    with context(Ctx { multiplier: 3 }):
        assert(combined(2) == 18)
    print("ok")
