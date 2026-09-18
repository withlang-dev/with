// T4 (fiber-aware yield) + T10 probe: Condvar + Barrier rendezvous.
// Minimal 2-participant version of test/spec/spec_ss14_17_condvar.w and
// spec_ss14_17_barrier.w (which cover 2-3 parties exhaustively).
// Fiber count stays far below the #995 1024 spawn cap.
use std.sync
use std.task.Task
use std.builtins.print

extern fn with_runtime_run_one_step() -> Unit

type Flag {
    ready: bool,
    value: i32,
}

async fn waiter(lock: &Mutex[Flag], cond: &Condvar) -> i32:
    with lock.enter_mut() as mut state:
        while not state.ready:
            cond.wait(lock)
        state.value

async fn notifier(lock: &Mutex[Flag], cond: &Condvar) -> i32:
    with lock.enter_mut() as mut state:
        state.ready = true
        state.value = 42
    cond.notify_one()
    0

async fn cross(barrier: &Barrier) -> bool:
    barrier.wait()

fn drive(a: &Task[i32], b: &Task[i32], c: &Task[bool], d: &Task[bool]):
    var steps = 0
    while (not a.is_done() or not b.is_done() or not c.is_done() or not d.is_done()) and steps < 128:
        unsafe { with_runtime_run_one_step() }
        steps = steps + 1

fn main:
    let lock = Mutex[Flag].new(Flag { ready: false, value: 0 })
    let cond = Condvar.new()
    let w = waiter(&lock, &cond)
    let n = notifier(&lock, &cond)
    let barrier = Barrier.new(2)
    let b1 = cross(&barrier)
    let b2 = cross(&barrier)
    drive(&w, &n, &b1, &b2)
    assert(n.await == 0)
    assert(w.await == 42)
    let _ = b1.await
    let _ = b2.await
    print("coord-ok")
