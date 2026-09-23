//! expect-stdout: 2
//! expect-stdout: 42 42
//! expect-stdout: 3 3
//! expect-stdout: 3

// #1481 / §12.4: "For non-`Copy` values, default capture is by place: the
// closure observes or mutates the original place according to its body."
// A let-bound closure (escaping by §12.3) still captures by place — the
// spec's own example is `let f = || xs.push(1); f() // mutates xs`. Creating
// the closure moves nothing: the binding stays usable, a reading closure
// may be called repeatedly, and a mutating one mutates the original.

type Resource { id: i32 }
impl Resource:
    fn drop(move self: Self): ()

fn main:
    var xs: Vec[i32] = Vec.new()
    let push_one = () => xs.push(1)
    push_one()
    push_one()
    print(xs.len())

    let r = Resource { id: 42 }
    let read_id = () => r.id
    print(f"{read_id()} {r.id}")

    let s = "abc".clone()
    let len = () => s.len() as i32
    print(f"{len()} {len()}")
    print(s.len())
