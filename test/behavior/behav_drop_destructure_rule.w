//! expect-stdout: whole 1
//! expect-stdout: wildcard-arm 2
//! expect-stdout: borrow 7 2
//! expect-stdout: enum-borrow 3 2
//! expect-stdout: take 8 2
//! expect-stdout: pid 5 2
//! expect-stdout: enum-whole 12
//! expect-stdout: drop-self 4 12
//! expect-stdout: end 12

// #1272 (Eric, 2026-09-22): the only way to skip a destructor is a spelling
// visible at the type's own boundary. `let t = r` and a `_` arm keep the value
// whole and run Drop exactly once; a borrowed subject binds views and never
// moves; a total destructure inside the type's own `move fn` (`drop`
// included) is the disarm and runs no Drop. Counting destructors: R adds 1,
// E adds 10, so each line's count pins exactly which destructors ran.

var count: i32 = 0
type R { repr: i32, other: i32 }
impl Drop for R:
    move fn drop(): count = count + 1
enum E { Idle | Running(i32) }
impl Drop for E:
    move fn drop(): count = count + 10

impl R:
    move fn take() -> i32:
        let { repr, other: _ } = self
        repr

impl E:
    move fn pid() -> i32:
        match self:
            E.Running(p) => p
            _ => -1

type Wrapped { inner: i32 }
impl Drop for Wrapped:
    move fn drop():
        // A total destructure inside `drop` itself: the field is read and no
        // second Drop runs.
        let { inner } = self
        print(f"drop-self {inner} {count}")

fn whole():
    let r = R { repr: 1, other: 0 }
    let t = r

fn wildcard_arm():
    let r = R { repr: 2, other: 0 }
    match r:
        _ => ()

fn enum_whole():
    let e = E.Running(1)
    let t = e

fn wrapped():
    let w = Wrapped { inner: 4 }

fn main:
    whole()
    print(f"whole {count}")
    wildcard_arm()
    print(f"wildcard-arm {count}")
    let r = R { repr: 7, other: 0 }
    match &r:
        R { repr } => print(f"borrow {repr} {count}")
    let e = E.Running(3)
    match &e:
        E.Running(p) => print(f"enum-borrow {p} {count}")
        _ => ()
    let r2 = R { repr: 8, other: 0 }
    print(f"take {r2.take()} {count}")
    let e2 = E.Running(5)
    print(f"pid {e2.pid()} {count}")
    enum_whole()
    print(f"enum-whole {count}")
    wrapped()
    print(f"end {count}")
