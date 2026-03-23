use c_import("string.h")

fn main() -> i32:
    let p: Option[*mut i32] = null
    assert(p.is_none())

    let q: Option[*mut i32] = None
    assert(q.is_none())

    let mut x = 7
    let raw = (&mut x) as *mut i32
    let some: Option[*mut i32] = Some(raw)
    assert(some.is_some())
    assert(some.unwrap() != null)

    if let .Some(found) = strchr("abc" as *const i8, 98):
        assert(found != null)
    else:
        return 1

    0
