// effect inference: escape_value — function that returns its parameter (non-Copy type)

type Resource { id: i32 }
impl Resource:
    fn drop(move self: Self): ()

fn take(r: Resource) -> Resource:
    return r

fn main:
    let r = Resource { id: 42 }
    let r2 = take(move r)   // ok: explicit move
    assert(r2.id == 42)
    print("ok\n")
