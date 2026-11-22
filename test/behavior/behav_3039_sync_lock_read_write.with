//! expect-stdout: 10 15 20 26 99
//! expect-stdout: ok

// #3039 (§5.3, §7.1, §7.5, §7.7, §14.3, §14.17): `Mutex.lock()` and
// `RwLock.read()` / `RwLock.write()` return guards usable directly in `with`
// blocks (`as data` and `as mut data`), alongside `RwLock.set(value)` and the
// `RwLockReadGuard` / `RwLockWriteGuard` aliases.

use std.sync.{Mutex, RwLock, RwLockReadGuard, RwLockWriteGuard}

fn hold_read(rw: &RwLock[i32]) -> i32:
    let g: RwLockReadGuard[i32] = rw.read()
    with g as v:
        *v

fn hold_write(rw: &RwLock[i32], delta: i32) -> i32:
    let g: RwLockWriteGuard[i32] = rw.write()
    with g as mut v:
        v += delta
    with rw.read() as v:
        *v

fn main:
    let m = Mutex.new(10)
    let a = with m.lock() as v:
        *v
    with m.lock() as mut v:
        v += 5
    let b = with m.lock() as v:
        *v

    let rw = RwLock.new(20)
    let c = hold_read(&rw)
    let d = hold_write(&rw, 6)
    let _peek = with rw.write() as v:
        *v
    rw.set(99)
    let e = with rw.read() as v:
        *v
    print(f"{a} {b} {c} {d} {e}")
    print("ok")
