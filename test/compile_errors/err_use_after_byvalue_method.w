//! expect-check-fail: use of moved value

// §3.8: a plain `T` method parameter consumes its argument, even when
// the method body only reads it. The receiver is not affected.
// First slice (#562): enforced for types with a user drop impl;
// full non-Copy enforcement is tracked by #564.

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
