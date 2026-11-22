//! expect-check-fail: use of moved value

type Resource { id: i32 }
impl Resource:
    fn drop(move self: Self): ()

fn take(r: Resource) -> Resource:
    return r

fn wrap_take(r: Resource) -> Resource:
    return take(move r)

fn main:
    let r = Resource { id: 1 }
    let _ = wrap_take(move r)
    let _ = r.id
