//! expect-check-fail: implicit parameter not provided; add a 'with' binding of the matching type

type Ctx { value: i32 }

fn f(x: i32, ctx: implicit Ctx) -> i32:
    x + ctx.value

fn main:
    let _ = f(1)
