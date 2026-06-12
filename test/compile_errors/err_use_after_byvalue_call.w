//! expect-check-fail: use of moved value

// §3.8: a plain `T` parameter consumes — the caller's binding is
// invalidated even when the callee body only reads the value.
// Enforced for every non-Copy type since #564's gate flip; the
// drop-impl case here was the #562 first slice, where the old
// behavior was an observable double-drop.

type Resource { id: i32 }
impl Resource:
    fn drop(move self: Self): ()

fn touch(r: Resource) -> i32:
    r.id

fn main:
    let r = Resource { id: 7 }
    let n = touch(r)
    print(f"{r.id} {n}")
