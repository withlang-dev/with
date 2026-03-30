//! expect-stdout: ok
//! args: --prelude=core

// Test: --prelude=core provides core types (Vec, assert, println)
// but does not provide std.iter functions (map, filter, sum).

fn main:
    let v: Vec[i32] = Vec.new()
    v.push(1)
    assert(v.len() == 1)
    print("ok")
