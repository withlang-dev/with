use std.sync
use std.builtins.print_i32

extern fn with_runtime_run_one_step() -> Unit

var RELEASE: i32 = 0
var AFTER: i32 = 0

async fn tick() -> i32: 1

fn delayed_init():
    while unsafe { RELEASE == 0 }:
        let _ = tick().await

async fn call(once: &Once, mark: bool) -> i32:
    once.call_once(delayed_init)
    if mark:
        unsafe { AFTER = AFTER + 1 }
    0

fn main:
    let once = Once.new()
    let owner = call(&once, false)
    unsafe { with_runtime_run_one_step() }
    let waiter = call(&once, true)
    unsafe { with_runtime_run_one_step() }
    waiter.cancel()
    unsafe { RELEASE = 1 }
    while not owner.is_done():
        unsafe { with_runtime_run_one_step() }
    owner.join_cleanup()
    waiter.join_cleanup()
    print_i32(if waiter.was_cancelled(): 1 else: 0)
    unsafe { print_i32(AFTER) }
    unsafe { assert(AFTER == 0) }
