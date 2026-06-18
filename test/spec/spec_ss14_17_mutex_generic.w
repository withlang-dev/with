//! expect-stdout: ok

use std.sync

extern fn with_runtime_run_one_step() -> Unit

type Counter {
    count: i32
    tag: i32
}

var MUTEX_DROP_TRACE = ""

type DropPayload {
    id: str,
}

impl Drop for DropPayload:
    fn drop(move self: Self):
        unsafe:
            MUTEX_DROP_TRACE = MUTEX_DROP_TRACE ++ self.id

async fn set_to_42(lock: &Mutex[i64]) -> i32:
    let next: i64 = 42
    lock.set(next)
    0

fn drive_until_done(task: &Task[i32]):
    var steps = 0
    while not task.is_done() and steps < 64:
        unsafe { with_runtime_run_one_step() }
        steps = steps + 1

fn test_generic_payload:
    let initial = Counter { count: 1 tag: 7 }
    let lock: Mutex[Counter] = Mutex[Counter].new(initial)
    let first = with lock.enter() as data:
        data.count + data.tag
    assert(first == 8)
    let first_tag = with lock.enter() as data:
        data.tag
    assert(first_tag == 7)
    let first_count = with lock.enter() as data:
        data.count
    assert(first_count == 1)
    let next = Counter { count: 10 tag: 20 }
    lock.set(next)
    let after_set = with lock.enter() as data:
        data.count + data.tag
    assert(after_set == 30)

fn test_i64_surface:
    let initial: i64 = 3
    let lock: Mutex[i64] = Mutex[i64].new(initial)
    let next: i64 = 7
    lock.set(next)
    let guard: MutexGuard[i64] = lock.enter()
    assert(guard.exit() == 7)

fn replace_drop_payload:
    let lock = Mutex[DropPayload].new(DropPayload { id: "old" })
    let before = with lock.enter() as data:
        data.id
    assert(before == "old")
    unsafe { assert(MUTEX_DROP_TRACE == "") }
    lock.set(DropPayload { id: "new" })

fn test_drop_payload_replacement_and_lock_drop:
    unsafe { MUTEX_DROP_TRACE = "" }
    replace_drop_payload()
    unsafe { assert(MUTEX_DROP_TRACE == "oldnew") }

fn test_contended_acquire_yields:
    let initial: i64 = 0
    let lock: Mutex[i64] = Mutex[i64].new(initial)
    let held: MutexGuardMut[i64] = lock.enter_mut()
    let task = set_to_42(&lock)
    unsafe { with_runtime_run_one_step() }
    assert(not task.is_done())
    assert(held.exit() == 0)
    drive_until_done(&task)
    assert(task.is_done())
    assert(task.await == 0)
    let guard: MutexGuard[i64] = lock.enter()
    assert(guard.exit() == 42)

fn main:
    test_generic_payload()
    test_i64_surface()
    test_drop_payload_replacement_and_lock_drop()
    test_contended_acquire_yields()
    print("ok")
