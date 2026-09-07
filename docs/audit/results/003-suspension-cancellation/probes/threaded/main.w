use std.task.Task
use std.builtins.print_i32

extern fn with_fiber_request_cancel_self() -> Unit
extern fn with_runtime_run_one_step() -> Unit
extern fn with_fiber_worker_count() -> i32

async fn tick() -> i32: 1

async fn child(should_cancel: bool, value: i32) -> i32:
    if should_cancel:
        unsafe { with_fiber_request_cancel_self() }
    let _ = tick().await
    value

async fn parent(should_cancel: bool, value: i32) -> i32:
    child(should_cancel, value).await

fn all_done(tasks: &Vec[Task[i32]]) -> bool:
    for i in 0..tasks.len() as i32:
        if not tasks.get(i as i64).is_done():
            return false
    true

fn main:
    print_i32(unsafe { with_fiber_worker_count() })
    assert(unsafe { with_fiber_worker_count() } == 4)
    var round = 0
    var total_cancelled = 0
    while round < 20:
        let tasks: Vec[Task[i32]] = Vec.new()
        var i = 0
        while i < 64:
            tasks.push(parent((i % 2) == 0, round * 64 + i))
            i = i + 1
        var steps = 0
        while not all_done(&tasks) and steps < 100000:
            unsafe { with_runtime_run_one_step() }
            steps = steps + 1
        assert(all_done(&tasks))
        while tasks.len() > 0:
            let task = tasks.remove(tasks.len() - 1)
            if task.was_cancelled():
                total_cancelled = total_cancelled + 1
            task.join_cleanup()
        round = round + 1
    print_i32(total_cancelled)
    assert(total_cancelled == 640)
    print("threaded-await-race-ok")
