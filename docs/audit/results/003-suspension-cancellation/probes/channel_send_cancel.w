use std.channel

extern fn with_fiber_live_fibers() -> i32
extern fn with_runtime_run_one_step() -> Unit

async fn blocked(tx: Sender[i32]) -> i32:
    tx.send(1)
    tx.send(2)
    0

fn main:
    let baseline = unsafe { with_fiber_live_fibers() }
    let (tx, rx) = chan[i32](1)
    let task = blocked(move tx)
    var steps = 0
    while unsafe { with_fiber_live_fibers() } < baseline + 1 and steps < 128:
        unsafe { with_runtime_run_one_step() }
        steps = steps + 1
    assert(unsafe { with_fiber_live_fibers() } >= baseline + 1)
    task.cancel()
    task.join_cleanup()
    assert(unsafe { with_fiber_live_fibers() } == baseline)
    let _ = rx.recv()
    print("channel-send-cancel-ok")
