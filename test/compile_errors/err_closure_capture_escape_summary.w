//! expect-check-fail: use of moved value

type Resource { id: i32 }
impl Resource:
    fn drop(move self: Self): ()

fn consume_capture(r: Resource) -> Resource:
    let f: fn() -> Resource = () => r
    f()

fn main:
    let r = Resource { id: 7 }
    let _ = consume_capture(r)
    let _ = r.id
