//! expect-check-fail: non-Copy argument passed to a function that consumes or escapes it

type Resource { id: i32 }
impl Resource:
    fn drop(move self: Self): ()

fn take(r: Resource) -> Resource:
    return r

fn wrap_take(r: Resource) -> Resource:
    return take(move r)

fn main:
    let r = Resource { id: 1 }
    let _ = wrap_take(r)   // error: wrap_take has escape_value on r (via transitive propagation)
