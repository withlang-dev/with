//! expect-check-fail: use of moved value

type Resource { id: i32 }
impl Resource:
    fn drop(move self: Self): ()

fn apply(f: fn() -> i32) -> i32: f()

fn main:
    let r = Resource { id: 42 }
    // Escaping closure captures non-Copy Resource — r is moved into closure.
    let f = () => r.id
    let _ = f()
    // Error: r was moved into the closure
    let _id = r.id
