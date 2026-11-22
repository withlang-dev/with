//! expect-stdout: 42 7 5 3 ok

// #2043 (D65): the method-call builtins (a sync scope's spawn and its
// handle's join, std Box.new / into_inner, Atomic.new, a channel endpoint's
// send / recv / close) reach codegen's builtin dispatch by the builtin Sema
// recorded for the call (check_method_call_parts), not by the callee's
// spelling or an LLVM-layout guess at ScopedJoinHandle.
use std.box.Box
use std.sync

fn main:
    let base = 40
    var joined = 0
    scope s =>:
        let handle = s.spawn(() => base + 2)
        joined = handle.join()
    let b = Box.new(7)
    let a: Atomic[i32] = Atomic.new(5)
    let (tx, rx) = chan[i32](1)
    tx.send(3)
    tx.close()
    print(f"{joined} {b.into_inner()} {a.load()} {rx.recv().unwrap()} ok")
