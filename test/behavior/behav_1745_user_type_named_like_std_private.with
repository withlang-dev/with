//! expect-stdout: 4 38
//! expect-stdout: 7 a 2
// #1745 (§18.2: a user-controlled declaration is never merged with the
// fallback tier, and std's own declarations are std's): a user type named
// like a std module's private type. std.sync's `Mutex.new[T]` names its
// private `MutexState`; the MIR paths of codegen mapped that TypeId to the
// user's same-named struct (only sema_type_to_llvm routed a std-tier
// declaration of a shadowed name to its `$std` slot), and the projected
// store `(*state).value = ...` failed "cannot lower projected assignment".
// std.task's private `PullCore` is the same shape through `g.pull()`.
use std.sync.Mutex

type MutexState { x: i32 }
type PullCore { tag: str, n: i32 }

gen fn upto(n: i32) -> i32:
    for i in 0..n:
        yield i

fn main:
    let c = MutexState { x: 4 }
    let m = Mutex.new(40)
    m.set(38)
    print(f"{c.x} {m.enter().exit()}")
    let core = PullCore { tag: "a", n: 7 }
    var p = upto(3).pull()
    let _ = p.next()
    let _ = p.next()
    print(f"{core.n} {core.tag} {p.next().unwrap()}")
