//! expect-check-fail: @[effect] pin on 'r' does not match inferred effects

// D120: a struct of values is a value; this one is declared a resource
// so it still moves and still takes no copy.
resource type Resource { id: i32 }
impl Resource:
    fn drop(move self: Self): ()

// pin declares only 'read', but body actually escapes the value
@[effect(r: read)]
fn take(r: Resource) -> Resource:
    return r

fn main:
    let r = Resource { id: 1 }
    let r2 = take(move r)
    assert(r2.id == 1)
