//! expect-stdout: ok

use std.sync

extern fn with_runtime_run_one_step() -> Unit

type Stats {
    reads: i32,
    writes: i32,
}

var RWLOCK_DROP_TRACE = ""

type DropPayload {
    id: str,
}

impl Drop for DropPayload:
    fn drop(move self: Self):
        unsafe:
            RWLOCK_DROP_TRACE = RWLOCK_DROP_TRACE ++ self.id

async fn write_to_42(lock: &RwLock[i64]) -> i32:
    lock.write(42 as i64)
    0

fn drive_until_done(task: &Task[i32]):
    var steps = 0
    while not task.is_done() and steps < 64:
        unsafe { with_runtime_run_one_step() }
        steps = steps + 1

fn test_generic_payload:
    let lock = RwLock[Stats].new(Stats { reads: 1, writes: 2 })
    let first = lock.enter()
    let second = lock.enter()
    let first_reads = with first as stats:
        stats.reads
    let second_writes = with second as stats:
        stats.writes
    assert(first_reads == 1)
    assert(second_writes == 2)
    with lock.enter_mut() as mut stats:
        stats.reads = stats.reads + 10
        stats.writes = stats.writes + 20
    let total = with lock.enter() as stats:
        stats.reads + stats.writes
    assert(total == 33)
    lock.write(Stats { reads: 5, writes: 6 })
    let after_write = with lock.enter() as stats:
        stats.reads + stats.writes
    assert(after_write == 11)

fn test_legacy_i64_surface:
    let lock = RwLock[i64].new(9 as i64)
    let before = with lock.enter() as value:
        *value
    assert(before == 9)
    with lock.enter_mut() as mut value:
        *value = *value + 2
    let after = with lock.enter() as value:
        *value
    assert(after == 11)

fn replace_drop_payload:
    let lock = RwLock[DropPayload].new(DropPayload { id: "old" })
    let before = with lock.enter() as data:
        data.id
    assert(before == "old")
    unsafe { assert(RWLOCK_DROP_TRACE == "") }
    lock.write(DropPayload { id: "new" })

fn test_drop_payload_replacement_and_lock_drop:
    unsafe { RWLOCK_DROP_TRACE = "" }
    replace_drop_payload()
    unsafe { assert(RWLOCK_DROP_TRACE == "oldnew") }

fn test_writer_waits_for_readers:
    let lock = RwLock[i64].new(0 as i64)
    let held = lock.enter()
    let task = write_to_42(&lock)
    unsafe { with_runtime_run_one_step() }
    assert(not task.is_done())
    assert(held.exit() == 0)
    drive_until_done(&task)
    assert(task.is_done())
    assert(task.await == 0)
    let guard = lock.enter()
    assert(guard.exit() == 42)

fn main:
    test_generic_payload()
    test_legacy_i64_surface()
    test_drop_payload_replacement_and_lock_drop()
    test_writer_waits_for_readers()
    print("ok")
