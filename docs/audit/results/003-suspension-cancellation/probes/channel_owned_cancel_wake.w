use std.channel
use std.task.Task
use std.builtins.print_i32

extern fn with_runtime_run_one_step() -> Unit

var DROPS: i32 = 0
var AFTER: i32 = 0

type Payload { value: i32 }

impl Drop for Payload:
    fn drop(move self: Self):
        unsafe { DROPS = DROPS + 1 }

fn payload(value: i32) -> Payload: Payload { value }
fn consume(value: Payload): ()

async fn sender(tx: Sender[Payload]) -> i32:
    tx.send(payload(1))
    tx.send(payload(2))
    unsafe { AFTER = AFTER + 1 }
    0

fn drive_until_done(task: &Task[i32]):
    var steps = 0
    while not task.is_done() and steps < 128:
        unsafe { with_runtime_run_one_step() }
        steps = steps + 1
    assert(task.is_done())

fn main:
    unsafe:
        DROPS = 0
        AFTER = 0
    let (tx, rx) = chan[Payload](1)
    let task = sender(move tx)
    unsafe { with_runtime_run_one_step() }
    task.cancel()
    consume(rx.recv().unwrap())
    drive_until_done(&task)
    consume(rx.recv().unwrap())
    print_i32(if task.was_cancelled(): 1 else: 0)
    let _ = task.await
    unsafe:
        print_i32(AFTER)
        print_i32(DROPS)
        assert(AFTER == 0)
        assert(DROPS == 2)
