//! expect-stdout: 47
//! expect-stdout: 42

// #1481 / §12.4: a closure passed as a direct argument holds `r` by place;
// `r` is untouched after the call (the old rule moved it into the closure).
type Resource { id: i32 }
impl Resource:
    fn drop(move self: Self): ()

fn apply(f: fn(i32) -> i32, x: i32) -> i32: f(x)

fn main:
    let r = Resource { id: 42 }
    print(apply(x => x + r.id, 5))
    print(r.id)
