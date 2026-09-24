//! expect-debug-alloc: leak count=0
//! expect-stdout: drop P 1
//! expect-stdout: 1
//! expect-stdout: drop P 2
//! expect-stdout: 2
//! expect-stdout: done

// #1605 / D63 (§12.4): a `move ||` closure sent to `spawn_os` owns its
// environment — a heap cell that travels with the closure value, freed by
// the thread that runs it, its Drop captures destroyed then and never in
// the creator's frame. A capture consumed inside the closure is dropped
// exactly once (before the fix: once in the thread and again when `main`
// ended), and the environment is destroyed before `join` returns.
use std.thread

type P { n: i32, v: Vec[i32] }
impl Drop for P:
    move fn drop(): print(f"drop P {self.n}")

fn main:
    let d = P { n: 1, v: Vec.new() }
    let h = spawn_os(move () => d.n)
    print(join(h))
    let e = P { n: 2, v: Vec.new() }
    let g = spawn_os(move () =>
        let mine = e
        mine.n
    )
    print(join(g))
    print("done")
