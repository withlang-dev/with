//! expect-check-fail: function body uses effects on 'r' not permitted by @[effect(...)] pin

type Resource { id: i32 }
impl Resource:
    fn drop(move self: Self): ()

// pin declares only 'read', but body actually escapes the value
@[effect(r = read)]
fn take(r: Resource) -> Resource:
    return r

fn main:
    let r = Resource { id: 1 }
    let r2 = take(move r)
    assert(r2.id == 1)
