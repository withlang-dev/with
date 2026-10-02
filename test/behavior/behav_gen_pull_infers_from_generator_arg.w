//! expect-stdout: 0
//! expect-stdout: 1
//! expect-stdout: 2

// D69 (§13.4): `g.pull()` is `gen_pull[T](g: impl Gen[T])`; T is bound from
// the generator's element type with nothing annotated. Pinned as a user
// program after a stage2 that embedded a sibling tree's std/task.w (a
// `[T, G: Gen[T]](g: G)` spelling this Sema cannot bind T from) rejected
// exactly this line and read as a self-miscompile (2026-10-02).
use std.task.Pulled
gen fn ns(n: i32) -> i32:
    for i in 0..n:
        yield i
fn main:
    var p = ns(3).pull()
    print(p.next().unwrap())
    print(p.next().unwrap())
    print(p.next().unwrap())
