//! expect-stdout: ok

type Ctx { multiplier: i32 }
type Scale { value: i32 }

fn Scale.apply(self: &Self, ctx: implicit Ctx) -> i32:
    self.value * ctx.multiplier

fn main:
    let s = Scale { value: 7 }
    with context(Ctx { multiplier: 6 }):
        assert(s.apply() == 42)
    print("ok")
