//! expect-check-fail: non-Copy argument passed to a function that consumes or escapes it

type Resource { id: i32 }
impl Resource:
    fn drop(move self: Self): ()

fn take(r: Resource) -> Resource:
    return r

fn main:
    let r = Resource { id: 1 }
    let _ = take(r)   // error: Resource is non-Copy and take escapes it; needs 'move r'
