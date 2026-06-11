//! expect-check-fail: use of moved value

type Resource { id: i32 }
impl Resource:
    fn drop(move self: Self): ()

fn consume_store(v: Resource) -> i32:
    let local = v
    local.id

fn main:
    let r = Resource { id: 1 }
    let _ = consume_store(r)
    let _ = r.id
