//! expect-stdout: 15
//! expect-stdout: true
//! expect-stdout: 4

// Law 1: `Atomic.new(v)` with no annotation holds what it is built from,
// `Atomic[type of v]`, as an annotated one holds the annotation's type. It
// was typed as the bare `Atomic`, so every `load` on it was an unknown
// method.
use std.collections.Atomic

global total: Atomic[i64] = Atomic.new(10)

fn main:
    let hits = Atomic.new(0)
    hits.fetch_add(5, .Relaxed)
    let sum: i64 = hits.load(.Relaxed) + total.load(.Relaxed)
    print(sum)
    let flag = Atomic.new(false)
    flag.store(true, .Relaxed)
    print(flag.load(.Relaxed))
    let small = Atomic.new(3)
    print(small.load(.Relaxed) + 1)
