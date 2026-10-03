//! expect-check-fail: implicit parameter `ctx` takes a non-Copy `Ctx`, which is never filled implicitly (§7.3a)
// D87 (§7.3a): an implicit fill never consumes the binding, so a non-Copy
// `implicit Ctx` is not filled from `with c(...)`. The help names both
// spellings that work: pass it explicitly (`ctx: c`, a move) or declare
// `ctx: implicit &Ctx`. (#2049: it was filled with a copy — a double free.)
type Ctx { name: str }

fn take(x: i32, ctx: implicit Ctx) -> i32: x + ctx.name.len() as i32

fn main:
    with c(Ctx { name: "abc".clone() }):
        print(f"{take(1)}")
