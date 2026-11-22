//! args: --validate-all
//! expect-check-stdout: validate-all: ok

// #1990: `t.join_cleanup()` cancels the task, awaits its cleanup and frees
// its result buffer: it releases the handle the way a scope-exit cleanup
// does (#1944). The lowering cancelled the receiver's scheduled drop but
// read the handle by byte copy into a temporary, so the MIR never recorded
// that the call takes it and the ownership validator reported the Task
// "still Init at return" — for a local and for a parameter alike. The
// cleanup await takes an owned receiver by `move`; cancel only observes it.

use std.task.Task

async fn one() -> i32: 1

fn local_task:
    let t = one()
    t.cancel()
    t.join_cleanup()

fn param_task(p: Task[i32]):
    p.cancel()
    p.join_cleanup()

fn cond_task(p: Task[i32], early: bool) -> i32:
    if early:
        p.join_cleanup()
        return 0
    p.join_cleanup()
    1

fn main:
    local_task()
    param_task(one())
    print(f"{cond_task(one(), true) + cond_task(one(), false)}")
