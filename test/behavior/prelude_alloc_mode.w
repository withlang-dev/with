//! expect-stdout: ok
//! args: --prelude=alloc

// Test: --prelude=alloc provides core + allocation-backed containers.

fn main:
    let v: Vec[i32] = Vec.new()
    v.push(1)
    assert(v.len() == 1)
    print("ok")
