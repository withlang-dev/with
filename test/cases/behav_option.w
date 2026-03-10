//! expect-stdout: ok

// Behavior test: Option type — Some, None, is_some, unwrap
// Uses ?T shorthand for Option[T].

fn find_positive(n: i32) -> ?i32:
    if n > 0:
        Some(n)
    else:
        None

fn test_some:
    let r = find_positive(42)
    var found = false
    if let .Some(v) = r:
        assert(v == 42)
        found = true
    assert(found)

fn test_none:
    let r = find_positive(-5)
    var is_none = true
    if let .Some(_) = r:
        is_none = false
    assert(is_none)

fn test_option_with_if_let:
    let a = find_positive(10)
    let b = find_positive(-1)
    var a_val = 0
    if let .Some(v) = a:
        a_val = v
    assert(a_val == 10)
    var b_val = -1
    if let .Some(v) = b:
        b_val = v
    assert(b_val == -1)

fn test_option_chaining:
    let a = find_positive(5)
    var result = 0
    if let .Some(v) = a:
        let b = find_positive(v * 2)
        if let .Some(v2) = b:
            result = v2
    assert(result == 10)

fn main:
    test_some()
    test_none()
    test_option_with_if_let()
    test_option_chaining()
    println("ok")
