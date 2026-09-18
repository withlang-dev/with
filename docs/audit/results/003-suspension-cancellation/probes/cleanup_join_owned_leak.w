use std.task.Task
use std.builtins.print_i32

extern fn with_alloc(size: i64) -> *mut u8
extern fn with_free(ptr: *mut u8) -> Unit
extern fn with_runtime_run_one_step() -> Unit

var DROPS: i32 = 0

type Resource { ptr: *mut u8 }

impl Drop for Resource:
    fn drop(move self: Self):
        unsafe:
            with_free(self.ptr)
            DROPS = DROPS + 1

async fn ready() -> Resource: unsafe { Resource { ptr: with_alloc(32) } }

fn drive_until_done(task: &Task[Resource]):
    var steps = 0
    while not task.is_done() and steps < 128:
        unsafe { with_runtime_run_one_step() }
        steps = steps + 1
    assert(task.is_done())

fn main:
    unsafe { DROPS = 0 }
    let task = ready()
    drive_until_done(&task)
    task.join_cleanup()
    unsafe { print_i32(DROPS) }
