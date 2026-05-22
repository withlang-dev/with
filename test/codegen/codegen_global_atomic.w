//! expect-stdout: ok

var counter: Atomic[i32]

fn main:
    counter.store(1, .SeqCst)
    assert(counter.load(.SeqCst) == 1)
    assert(counter.swap(2, .SeqCst) == 1)
    assert(counter.load(.SeqCst) == 2)
    print("ok")
