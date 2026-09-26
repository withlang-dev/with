//! expect-check-fail: use of moved value

// #1627 / #764: `.Some(ctx)` into an owned `Option[Ctx]` payload consumes
// `ctx` exactly as `Some(ctx)` does. The shorthand marked nothing, so the
// read below compiled and printed the moved-out (blank) string.

type Ctx { n: i32, tag: str }

fn h(ud: Option[Ctx]) -> i32: match ud:
    Some(u) => u.n
    None => -1

fn main:
    let ctx = Ctx { n: 40, tag: "alpha".clone() }
    print(h(.Some(ctx)))
    print(ctx.tag)
