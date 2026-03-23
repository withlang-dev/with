//! expect-stdout: ok

// Behavior test: let-else pattern matching at runtime

fn get_some() -> ?i32:
    Some(42)

fn get_none() -> ?i32:
    None

fn extract_or_default(opt: ?i32) -> i32:
    let .Some(v) = opt else return -1
    v

fn main:
    let a = get_some()
    let b = get_none()
    assert(extract_or_default(a) == 42)
    assert(extract_or_default(b) == -1)
    println("ok")
