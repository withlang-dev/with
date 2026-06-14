//! expect-error: implicit parameter cannot have a default value

type Ctx { value: i32 }

fn f(ctx: implicit Ctx = Ctx { value: 1 }) -> i32:
    ctx.value

fn main:
    let _ = f()
