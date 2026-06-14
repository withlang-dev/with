//! expect-stdout: ok

type Ctx { multiplier: i32 }

fn by_value(x: i32, ctx: implicit Ctx) -> i32:
    x * ctx.multiplier

fn by_ref(x: i32, ctx: implicit &Ctx) -> i32:
    x * ctx.multiplier

fn combined(x: i32, ctx: implicit Ctx) -> i32:
    by_ref(by_value(x))

fn main:
    with context(Ctx { multiplier: 3 }):
        assert(by_value(4) == 12)
        assert(by_ref(5) == 15)
        assert(combined(2) == 18)
    print("ok")
