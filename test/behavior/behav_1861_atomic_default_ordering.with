//! expect-stdout: 4
//! expect-stdout: x7
//! expect-stdout: x3
//! expect-stdout: 2 4

// #1861 (§14.17.1, §18.5): an Atomic method with its ordering argument
// omitted is SeqCst. MIR materializes the omitted ordering as the call's
// own operand, so no backend reads past the call's operands into the next
// call (the f-string's literal text was read as the ordering, and a global
// initializer read off the end of the operand table).

use std.sync

fn helper(u: u32) -> (i64, i64):
    let b: Atomic[i64] = Atomic.new(u)
    let b0 = b.load()
    b.fetch_add(u)
    (b0, b.load())

let a: Atomic[i64] = Atomic.new(4)
let v = a.load()
a.fetch_add(3)
print(f"{v}")
print(f"x{a.load()}")
let c: Atomic[i64] = Atomic.new(4)
c.store(3)
print(f"x{c.load()}")
let (h0, h1) = helper(2)
print(f"{h0} {h1}")
