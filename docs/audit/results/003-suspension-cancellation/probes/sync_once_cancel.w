use std.sync

extern fn with_runtime_run_one_step() -> Unit

async fn tick() -> i32: 1

fn never_init():
    while true:
        let _ = tick().await

async fn call(once: &Once) -> i32:
    once.call_once(never_init)
    0

fn main:
    let once = Once.new()
    let owner = call(&once)
    unsafe { with_runtime_run_one_step() }
    let waiter = call(&once)
    unsafe { with_runtime_run_one_step() }
    waiter.cancel()
    waiter.join_cleanup()
    owner.cancel()
    owner.join_cleanup()
    print("once-cancel-ok")
