//! expect-stdout: enter exit drop | enter exit drop | 4 5 | 10
// #978: a guarded `with` drops its guard when the scope ends, after
// `with_exit`, on every way out (here: falling off the end and a
// `return`). The guard was never dropped: its storage ended with the value
// still live, so a lock guard whose Drop releases the lock held it, and the
// second `with lock.enter()` spun forever.
use std.sync

var TRACE = ""

type Traced { n: i32 }

impl Scoped[i32] for Traced:
    fn with_enter(self: &Self) -> i32:
        TRACE = TRACE ++ "enter "
        self.n
    fn with_exit(self: &Self):
        TRACE = TRACE ++ "exit "

impl Drop for Traced:
    move fn drop():
        TRACE = TRACE ++ "drop"

fn early(flag: bool) -> i32:
    with Traced { n: 1 } as n:
        if flag: return n
    0

fn main:
    let _ = with Traced { n: 2 } as n:
        n
    let first = TRACE
    TRACE = ""
    let _ = early(true)
    let second = TRACE
    let lock: Mutex[i64] = Mutex[i64].new(3)
    let a = with lock.enter() as v:
        v + 1
    let b = with lock.enter() as v:
        v + 2
    let rw: RwLock[i64] = RwLock[i64].new(4)
    with rw.enter_mut() as mut v:
        v = v + 5
    let c = with rw.enter() as v:
        v + 1
    print(f"{first} | {second} | {a} {b} | {c}")
