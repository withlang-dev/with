//! expect-stdout: ok

// Behavior test: if-let pattern matching at runtime

fn get_some() -> ?i32:
    Some(42)

fn get_none() -> ?i32:
    None

fn describe(opt: &?i32) -> str:
    if let .Some(x) = opt:
        "has:" ++ int_to_string(*x)
    else:
        "nothing"


fn main:
    let a = get_some()
    let b = get_none()
    assert(describe(a) == "has:42")
    assert(describe(b) == "nothing")
    // if-let without else
    var found = false
    if let .Some(v) = a:
        found = true
    assert(found)
    print("ok")
