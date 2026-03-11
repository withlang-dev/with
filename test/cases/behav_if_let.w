//! expect-stdout: ok

// Behavior test: if-let pattern matching
// Tests: if let .Some(x) = expr, with else branches

fn find(n: i32) -> ?i32:
    if n > 0:
        Some(n * 10)
    else:
        None

fn test_if_let_some:
    let r = find(5)
    var got = 0
    if let .Some(v) = r:
        got = v
    assert(got == 50)

fn test_if_let_none:
    let r = find(-1)
    var is_none = true
    if let .Some(_) = r:
        is_none = false
    assert(is_none)

fn test_if_let_else:
    let r = find(3)
    let msg = if let .Some(v) = r:
        "found"
    else:
        "missing"
    assert(msg == "found")
    let r2 = find(-1)
    let msg2 = if let .Some(v) = r2:
        "found"
    else:
        "missing"
    assert(msg2 == "missing")

fn main:
    test_if_let_some()
    test_if_let_none()
    test_if_let_else()
    println("ok")
