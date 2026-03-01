//! expect-stdout: ok

// Behavior test: if-let pattern matching at runtime

fn get_some() -> ?i32:
    Some(42)

fn get_none() -> ?i32:
    None

fn describe(opt: ?i32) -> str:
    if let .Some(x) = opt:
        "has:" ++ i32_to_str(x)
    else:
        "nothing"

extern fn i32_to_str(n: i32) -> str

fn main:
    let a = get_some()
    let b = get_none()
    assert(describe(a) == "has:42")
    assert(describe(b) == "nothing")
    // if-let without else
    var found = false
    if let .Some(v) = a:
        found = true
    assert(found == true)
    println("ok")
