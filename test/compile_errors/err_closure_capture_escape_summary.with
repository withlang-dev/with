//! expect-check-fail: use of moved value

// §D5 share-place: the closure captures and returns `r`, so `r` escapes the
// call and must be transferred explicitly with `move`. After the explicit move,
// using `r.id` is a use-after-move — the error this test pins.

type Resource { id: i32 }
impl Resource:
    fn drop(move self: Self): ()

fn consume_capture(r: Resource) -> Resource:
    let f: fn() -> Resource = () => r
    f()

fn main:
    let r = Resource { id: 7 }
    let _ = consume_capture(move r)
    let _ = r.id
