//! expect-check-fail: @[effect] pin on 'r' does not match inferred effects

type Resource { id: i32 }
impl Resource:
    fn drop(move self: Self): ()

// pin declares an escaping value, but the body only reads the parameter.
@[effect(r: escape_value)]
fn read_resource(r: Resource) -> i32:
    r.id

fn main:
    let r = Resource { id: 1 }
    let _ = read_resource(r)
