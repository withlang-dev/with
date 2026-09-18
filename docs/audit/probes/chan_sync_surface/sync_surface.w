// T10 stdlib-foundations surface probe (sync context, no fibers).
// Exercises every public constructor/accessor in lib/std/sync.w:
// Mutex, RwLock, Once, Atomic[i64], fence. Condvar/Barrier (fiber-aware)
// are covered in sync_coord_surface.w.
use std.sync
use std.builtins.print

var ONCE_COUNT = 0

fn init_once:
    unsafe:
        ONCE_COUNT = ONCE_COUNT + 1

fn main:
    let m = Mutex[i64].new(40 as i64)
    let g = m.enter()
    assert(g.exit() == 40)
    m.set(41 as i64)
    assert(mutex_get(&m) == 41)
    let v = with m.enter() as data:
        *data + 1
    assert(v == 42)

    let rw = RwLock[i64].new(7 as i64)
    let rg = rw.enter()
    assert(rg.exit() == 7)
    rw.write(9 as i64)
    assert(rwlock_read(&rw) == 9)
    let wsum = with rw.enter() as state:
        *state + 1
    assert(wsum == 10)

    let once = Once.new()
    unsafe { ONCE_COUNT = 0 }
    once.call_once(init_once)
    once.call_once(init_once)
    unsafe { assert(ONCE_COUNT == 1) }

    let a = atomic_new(10 as i64)
    assert(atomic_load(&a) == 10)
    fence(.SeqCst)
    print("sync-surface-ok")
