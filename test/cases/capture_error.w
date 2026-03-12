//! expect-error: use of moved value
type Resource = { id: i32 }

fn Resource.drop(self: Resource):
    0

fn apply(f: fn(i32) -> i32, x: i32) -> i32: f(x)

fn main:
    let r = Resource { id: 42 }
    let f = x => x + r.id
    // r was moved into closure f (escaping: stored in let binding)
    let x = r.id
