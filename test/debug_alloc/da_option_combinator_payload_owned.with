//! expect-debug-alloc: leak count=0
// #1424: a combinator moves the payload out of its materialized subject, so the
// subject must not free it too. Each case once freed a List buffer twice: the
// closure owns its parameter (#1398) and the subject's scope-exit drop still ran.

fn some_list() -> Option[List[i32]]:
    var xs: List[i32] = List.new()
    xs.push(1)
    Some(xs)

fn main:
    let a = some_list().map((v) => v)
    let b = some_list().map((v) => v.len())
    let c = some_list().and_then((v) => Some(v.len()))
    let d = some_list().filter((v) => v.len() > 0)
    print(f"{a.is_some()} {b.unwrap_or(0)} {c.unwrap_or(0)} {d.is_some()}")
