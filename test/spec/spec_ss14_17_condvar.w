//! expect-stdout: ok

use std.sync

extern fn with_runtime_run_one_step() -> Unit

type Shared {
    ready: bool,
    value: i32,
}

async fn wait_for_ready(lock: &Mutex[Shared], cond: &Condvar) -> i32:
    with lock.enter_mut() as mut state:
        while not state.ready:
            cond.wait(lock)
        state.value

async fn publish(lock: &Mutex[Shared], cond: &Condvar, value: i32) -> i32:
    with lock.enter_mut() as mut state:
        state.ready = true
        state.value = value
    cond.notify_one()
    0

fn drive_pair(a: &Task[i32], b: &Task[i32]):
    var steps = 0
    while (not a.is_done() or not b.is_done()) and steps < 128:
        unsafe { with_runtime_run_one_step() }
        steps = steps + 1

fn test_notify_one:
    let lock = Mutex[Shared].new(Shared { ready: false, value: 0 })
    let cond = Condvar.new()
    with lock.enter_mut() as mut state:
        assert(not state.ready)
        state.value = 1
    let before = with lock.enter() as state:
        state.value
    assert(before == 1)
    let waiter = wait_for_ready(&lock, &cond)
    let notifier = publish(&lock, &cond, 42)
    drive_pair(&waiter, &notifier)
    assert(notifier.await == 0)
    assert(waiter.await == 42)

fn test_notify_all:
    let lock = Mutex[Shared].new(Shared { ready: false, value: 0 })
    let cond = Condvar.new()
    let first = wait_for_ready(&lock, &cond)
    let second = wait_for_ready(&lock, &cond)
    with lock.enter_mut() as mut state:
        state.ready = true
        state.value = 7
    cond.notify_all()
    drive_pair(&first, &second)
    assert(first.await == 7)
    assert(second.await == 7)

fn main:
    test_notify_one()
    test_notify_all()
    print("ok")
