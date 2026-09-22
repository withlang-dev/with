//! expect-stdout: a=3
//! expect-stdout: a=2
//! expect-stdout: b=3
//! expect-stdout: sum=13
//! expect-stdout: swapped=13
//! expect-stdout: cas=0

// #1287: an Atomic value operand is an owned `T` demand (§14.17.1). A
// positional element view (`xs[i]` / `xs.get(i)`, exact type `&i32` per
// §3.8/D27) materializes its Copy pointee, exactly as it does for an
// ordinary `fn take(v: i32)`; the intrinsic used to store the element's
// address on a global and nothing on a local.

use std.sync

var a: Atomic[i32] = Atomic.new(0)

fn main:
    var order = Vec.new()
    order.push(1)
    order.push(2)
    order.push(3)
    order.push(10)
    a.store(order[2], .SeqCst)
    print(f"a={a.load(.SeqCst)}")
    a.store(order.get(1), .SeqCst)
    print(f"a={a.load(.SeqCst)}")
    let b: Atomic[i32] = Atomic.new(0)
    b.store(order[2], .SeqCst)
    print(f"b={b.load(.SeqCst)}")
    let old = b.fetch_add(order[3], .SeqCst)
    print(f"sum={b.load(.SeqCst) + old - 3}")
    let prev = b.swap(order[0], .SeqCst)
    print(f"swapped={prev}")
    match b.compare_exchange(order[0], order[1], .SeqCst, .Relaxed):
        Ok(_) => print(f"cas={b.load(.SeqCst) - 2}")
        Err(_) => print("cas=failed")
