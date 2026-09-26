//! expect-stdout: 40
//! expect-stdout: 41
//! expect-stdout: 43
//! expect-stdout: 44
//! expect-stdout: 45
//! expect-stdout: alpha-alpha

// #1627 (§3.8, D22): a place passed where the payload is `&T` borrows —
// `Some(ctx)` against `Option[&Ctx]` observes `ctx` the way `h(ctx)`
// against `&Ctx` does, and Option is transparent to the view's origin.
// Every constructor spelling shares the rule: `Some(ctx)`,
// `Option[&Ctx].Some(ctx)` and `.Some(ctx)`, as an argument and under an
// annotated binding. `ctx` is read after each; its string field proves
// nothing moved its bytes out.

type Ctx { n: i32, tag: str }

fn h(ud: Option[&Ctx]) -> i32: match ud:
    Some(u) => u.n + u.tag.len() as i32 - 5
    None => -1

fn main:
    let ctx = Ctx { n: 40, tag: "alpha".clone() }
    print(h(Some(ctx)))
    let z: Option[&Ctx] = Some(ctx)
    print(h(z) + 1)
    print(h(Option[&Ctx].Some(ctx)) + 3)
    print(h(.Some(ctx)) + 4)
    print(ctx.n + 5)
    print(f"{ctx.tag}-{ctx.tag}")
