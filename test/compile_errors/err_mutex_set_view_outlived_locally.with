//! expect-check-fail: may originate from `x`, which no longer lives here

// #1778 (§21.1 rule 6, D22): a view stored through `Mutex.set` into a local
// mutex makes the mutex a holder of the view's origin, as `List.push` does:
// reading the mutex after `x` died reads a dangling reference and is
// refused.
use std.sync

fn main:
    let m: Mutex[Option[&i32]] = Mutex.new(None)
    if true:
        let x = 5
        m.set(Some(&x))
    with m.enter() as held:
        match held:
            Some(r) => print(f"{r}")
            None => print("none")
