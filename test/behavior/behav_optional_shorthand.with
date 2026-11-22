//! expect-stdout: ok

fn make_some() -> ?i32:
    .Some(42)

fn make_none() -> ?i32:
    .None

fn main:
    // ?i32 with .Some
    let a: ?i32 = .Some(42)
    assert(a.unwrap() == 42)
    assert(a.is_some())
    assert(not a.is_none())

    // ?i32 with .None
    let b: ?i32 = .None
    assert(b.is_none())
    assert(not b.is_some())

    // ?str
    let c: ?str = .Some("hello")
    assert(c.unwrap() == "hello")

    // Return ?T from function
    let d = make_some()
    assert(d.unwrap() == 42)
    let e = make_none()
    assert(e.is_none())

    // ?T and Option[T] are the same type
    let f: Option[i32] = .Some(99)
    let g: ?i32 = .Some(99)
    assert(f.unwrap() == g.unwrap())

    print("ok")
