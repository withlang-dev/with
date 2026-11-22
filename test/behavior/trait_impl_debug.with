//! expect-stdout: ok

// Test: prelude-provided Debug trait impls for i32, bool, str.

fn main:
    let n: i32 = 42
    assert(n.debug_str() == "42")

    let t = true
    assert(t.debug_str() == "true")
    let f = false
    assert(f.debug_str() == "false")

    let s = "hello"
    assert(s.debug_str() == "\"hello\"")

    print("ok")
