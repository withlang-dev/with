//! expect-check-fail: use of moved value

// §3.8: a plain `T` method parameter consumes its argument, even when
// the method body only reads it. The receiver is not affected.
// Enforced for every non-Copy type since #564's gate flip; the
// drop-impl case here was the #562 first slice.

type Resource { id: i32 }
impl Resource:
    fn drop(move self: Self): ()

type Sink { n: i32 }

fn Sink.consume(self: &Self, r: Resource) -> i32:
    r.id

fn main:
    let s = Sink { n: 0 }
    let r = Resource { id: 9 }
    let n = s.consume(r)
    print(f"{r.id} {n}")
