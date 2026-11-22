// Transitive effect propagation: a wrapper that passes its param to a consuming callee
// inherits the consume/escape_value effect, so callers must use move/copy appropriately.

type Resource { id: i32 }
impl Resource:
    fn drop(move self: Self): ()

fn take(r: Resource) -> Resource:
    return r

fn wrap_take(r: Resource) -> Resource:
    return take(move r)   // take has escape_value on r; propagates to wrap_take

fn main:
    let r = Resource { id: 99 }
    let r2 = wrap_take(move r)
    assert(r2.id == 99)
    print("ok\n")
