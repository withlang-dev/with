//! expect-stdout: 8
//! expect-stdout: 9

// `Atomic.new(v)` builds the cell, in a global's initializer (std.random's
// state, #985) and in a body alike. The C backend had no lowering for it,
// and typed the result by another type's `new`.
use std.collections.Atomic

global counter: Atomic[i64] = Atomic.new(5)

fn main:
    let local: Atomic[i64] = Atomic.new(3)
    print(local.load(.Relaxed) + counter.load(.Relaxed))
    counter.store(6, .Relaxed)
    print(local.load(.Relaxed) + counter.load(.Relaxed))
