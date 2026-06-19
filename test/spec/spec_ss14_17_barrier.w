//! expect-stdout: ok

use std.sync

extern fn with_runtime_run_one_step() -> Unit

type Counts {
    before: i32,
    after: i32,
    leaders: i32,
}

async fn cross_barrier(barrier: &Barrier, counts: &Mutex[Counts]) -> i32:
    with counts.enter_mut() as mut c:
        c.before = c.before + 1
    let leader = barrier.wait()
    with counts.enter_mut() as mut c:
        if c.before == 3:
            c.after = c.after + 1
        if leader:
            c.leaders = c.leaders + 1
    0

fn drive_three(a: &Task[i32], b: &Task[i32], c: &Task[i32]):
    var steps = 0
    while (not a.is_done() or not b.is_done() or not c.is_done()) and steps < 128:
        unsafe { with_runtime_run_one_step() }
        steps = steps + 1

fn main:
    let barrier = Barrier.new(3)
    let counts = Mutex[Counts].new(Counts { before: 0, after: 0, leaders: 0 })
    let a = cross_barrier(&barrier, &counts)
    let b = cross_barrier(&barrier, &counts)
    let c = cross_barrier(&barrier, &counts)
    drive_three(&a, &b, &c)
    assert(a.await == 0)
    assert(b.await == 0)
    assert(c.await == 0)
    let summary = with counts.enter() as snapshot:
        snapshot.before * 100 + snapshot.after * 10 + snapshot.leaders
    assert(summary == 331)
    print("ok")
