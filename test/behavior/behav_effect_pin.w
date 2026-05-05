// @[effect] pin: function body exactly matches the declared floor effect

type Resource { id: i32 }
impl Resource:
    fn drop(move self: Self): ()

@[effect(r = escape_value)]
fn take(r: Resource) -> Resource:
    return r

fn main:
    let r = Resource { id: 7 }
    let r2 = take(move r)
    assert(r2.id == 7)
    print("ok\n")
