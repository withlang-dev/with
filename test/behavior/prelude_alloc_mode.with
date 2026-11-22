//! expect-stdout: ok
//! args: --prelude=alloc

// Test: --prelude=alloc provides core + allocation-backed containers.

fn main:
    let v: List[i32] = List.new()
    v.push(1)
    assert(v.len() == 1)
    print("ok")
