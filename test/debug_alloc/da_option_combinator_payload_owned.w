//! expect-debug-alloc: leak count=0
// #1424: a combinator moves the payload out of its materialized subject, so the
// subject must not free it too. Each case once freed a Vec buffer twice: the
// closure owns its parameter (#1398) and the subject's scope-exit drop still ran.

fn some_vec() -> Option[Vec[i32]]:
    var xs: Vec[i32] = Vec.new()
    xs.push(1)
    Some(xs)

fn main:
    let a = some_vec().map((v) => v)
    let b = some_vec().map((v) => v.len())
    let c = some_vec().and_then((v) => Some(v.len()))
    let d = some_vec().filter((v) => v.len() > 0)
    print(f"{a.is_some()} {b.unwrap_or(0)} {c.unwrap_or(0)} {d.is_some()}")
