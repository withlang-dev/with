// Test: std.sync import
use std.sync

fn main() -> i32 =
    var m = mutex_new(10)
    assert(mutex_get(m) == 10)
    mutex_set(&mut m, 42)
    assert(mutex_get(m) == 42)

    var rw = rwlock_new(5)
    assert(rwlock_read(rw) == 5)
    rwlock_write(&mut rw, 9)
    assert(rwlock_read(rw) == 9)

    var a = atomic_new(1)
    assert(atomic_add(&mut a, 5) == 6)

    var b = atomic_new(1)
    atomic_store(&mut b, 7)
    assert(atomic_load(b) == 7)
    0
