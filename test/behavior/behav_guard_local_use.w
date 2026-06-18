//! expect-stdout: ok

use std.sync

fn test_mutex_guards:
    let m = Mutex[i64].new(40 as i64)
    let g = m.enter()
    assert(g.exit() == 40)
    let gm = m.enter_mut()
    assert(gm.exit() == 40)

fn test_rwlock_guards:
    let rw = RwLock[i64].new(41 as i64)
    let rg = rw.enter()
    assert(rg.exit() == 41)
    let wg = rw.enter_mut()
    assert(wg.exit() == 41)

fn test_guarded_with_blocks:
    let m = Mutex[i64].new(40 as i64)
    let value = with m.enter() as data:
        *data + 2
    assert(value == 42)
    var seen = 0
    with m.enter_mut() as mut data:
        data = data + 2
        seen = data
    assert(seen == 42)

fn main:
    test_mutex_guards()
    test_rwlock_guards()
    test_guarded_with_blocks()
    print("ok")
