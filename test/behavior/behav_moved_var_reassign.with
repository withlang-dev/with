//! expect-stdout: ok

// Spec §2.4 reassignment + §3.8 consume: a moved-out var is a legal
// assignment target — the store revives the binding. Previously the
// LHS check flagged the reassignment itself as a use of a moved value.

type Resource { id: i32 }
impl Resource:
    fn drop(move self: Self): ()

fn consume(r: Resource) -> i32:
    r.id

fn main:
    var r = Resource { id: 1 }
    let a = consume(r)
    r = Resource { id: 2 }
    let b = consume(r)
    assert(a == 1)
    assert(b == 2)
    print("ok")
