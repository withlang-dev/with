//! expect-stdout: ok

// Test: prelude functions resolve without explicit imports.

fn main:
    let v: Vec[i32] = Vec.new()
    v.push(42)
    assert(v.len() == 1)
    assert(v.get(0) == 42)
    print("ok")
