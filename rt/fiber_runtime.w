// rt/fiber_runtime.w -- migrated fiber helpers that do not need direct context
// switching or queue ownership.

extern fn with_fiber_in_fiber() -> i32
extern fn with_fiber_yield() -> void
extern fn with_runtime_has_fibers() -> i32
extern fn with_runtime_run_one_step() -> void
extern fn with_runtime_fiber_is_completed(fiber_id: i32) -> i32
extern fn with_runtime_request_cancel(fiber_id: i32) -> i32
extern fn with_runtime_current_cancel_requested() -> i32
extern fn with_runtime_current_set_cancel_requested() -> void
extern fn with_runtime_current_set_cancelled_return() -> void
extern fn with_runtime_completed_cancelled_return(fiber_id: i32) -> i32

@[c_export("with_fiber_select")]
pub fn fiber_select(fiber_ids: *const i32, count: i32, result_index: *mut i32):
    while true:
        var i = 0
        while i < count:
            let fid = unsafe: *((fiber_ids as i64 + i as i64 * 4) as *const i32)
            if with_runtime_fiber_is_completed(fid) != 0:
                unsafe:
                    *result_index = i
                return
            i = i + 1

        if with_fiber_in_fiber() != 0:
            with_fiber_yield()
        else if with_runtime_has_fibers() != 0:
            with_runtime_run_one_step()
        else:
            unsafe:
                *result_index = -1
            return

@[c_export("with_fiber_cancel")]
pub fn fiber_cancel(fiber_id: i32) -> i32:
    if with_runtime_fiber_is_completed(fiber_id) != 0:
        return 1
    with_runtime_request_cancel(fiber_id)

@[c_export("with_fiber_is_cancelled")]
pub fn fiber_is_cancelled() -> i32:
    with_runtime_current_cancel_requested()

@[c_export("with_fiber_set_cancelled_return")]
pub fn fiber_set_cancelled_return():
    with_runtime_current_set_cancelled_return()

@[c_export("with_fiber_was_cancelled_return")]
pub fn fiber_was_cancelled_return(fiber_id: i32) -> i32:
    with_runtime_completed_cancelled_return(fiber_id)

@[c_export("with_fiber_request_cancel_self")]
pub fn fiber_request_cancel_self():
    with_runtime_current_set_cancel_requested()
