//! expect-check-fail: use of moved value
// #2049 (D5, §3.8, §7.3a): a plain `Ctx` implicit parameter takes the
// context, as `take(1, c)` would; the second fill reads a moved binding.
// The help names the borrowing spelling, `implicit &Ctx`.
type Ctx { name: str }

fn take(x: i32, ctx: implicit Ctx) -> i32: x + ctx.name.len() as i32

fn main:
    with c(Ctx { name: "abc".clone() }):
        let a = take(1)
        let b = take(2)
        print(f"{a} {b}")
