//! expect-stdout: ok
//! args: --prelude=core

// Test: --prelude=core provides non-alloc core types and builtins.

fn main:
    let opt: Option[i32] = Some(1)
    assert(opt.unwrap() == 1)
    print("ok")
