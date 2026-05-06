//! expect-check-fail: non-Copy argument passed to a function that consumes or escapes it

type Resource { id: i32 }
impl Resource:
    fn drop(move self: Self): ()

fn consume_capture(r: Resource) -> Resource:
    let f: fn() -> Resource = () => r
    f()

fn main:
    let r = Resource { id: 7 }
    let _ = consume_capture(r)
