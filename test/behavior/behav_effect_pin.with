//! expect-stdout: ok

// @[effect] pin: function body exactly matches the declared effect contract.

// D120: a struct of values is a value; this one is declared a resource
// so it still moves and still takes no copy.
resource type Resource { id: i32 }
impl Resource:
    fn drop(move self: Self): ()

@[effect(r: escape_value)]
fn take(r: Resource) -> Resource:
    return r

@[effect(value: read)]
fn read_only(value: Resource) -> i32:
    value.id

fn main:
    let r = Resource { id: 7 }
    let r2 = take(move r)
    assert(r2.id == 7)
    let other = Resource { id: 9 }
    assert(read_only(other) == 9)
    print("ok")
