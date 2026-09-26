//! expect-check-fail: cannot mutate `ctx` while `z` is a live view into it

// #1627 (§3.8, D22): `Some(ctx)` against `Option[&Ctx]` borrows `ctx`, and
// the Option carries the view's origin — so `ctx` cannot be written while
// `z` is still read.

type Ctx { n: i32 }

fn h(ud: Option[&Ctx]) -> i32: match ud:
    Some(u) => u.n
    None => -1

fn main:
    var ctx = Ctx { n: 1 }
    let z: Option[&Ctx] = Some(ctx)
    ctx.n = 2
    print(h(z))
