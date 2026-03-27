//! expect-stdout: ok

// Tests: Option with pointer types — nullable pointer optimization.
// Option[*T] is represented as the bare pointer (null = None).

fn main:
    // Option[*mut i32] from null → None
    let p: Option[*mut i32] = .None
    assert(p.is_none())

    // Option[*mut i32] from value → Some
    let mut x = 7
    let raw = (&mut x) as *mut i32
    let some: Option[*mut i32] = .Some(raw)
    assert(some.is_some())

    // Unwrap recovers the pointer
    let recovered = some.unwrap()
    assert(recovered != null)

    println("ok")
