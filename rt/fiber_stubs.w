// rt/fiber_stubs.w -- non-async lifecycle/fiber fallback surface.
//
// Linked only when fiber.o is not present, so these can be strong definitions.

extern fn abort() -> void

@[c_export("with_runtime_init")]
pub fn runtime_init():
    let _ = 0

@[c_export("with_runtime_run")]
pub fn runtime_run():
    let _ = 0

@[c_export("with_runtime_shutdown")]
pub fn runtime_shutdown():
    let _ = 0

@[c_export("with_runtime_run_one_step")]
pub fn runtime_run_one_step():
    let _ = 0

@[c_export("with_runtime_fiber_is_completed")]
pub fn runtime_fiber_is_completed(fiber_id: i32) -> i32:
    let _ = fiber_id
    0

@[c_export("with_runtime_take_completed_fiber")]
pub fn runtime_take_completed_fiber(fiber_id: i32, panic_msg_out: *mut *const u8, panic_msg_len_out: *mut i32, cancelled_return_out: *mut i32) -> i32:
    let _ = fiber_id
    unsafe:
        *panic_msg_out = 0 as *const u8
        *panic_msg_len_out = 0
        *cancelled_return_out = 0
    0

@[c_export("with_runtime_take_panicked_fiber")]
pub fn runtime_take_panicked_fiber(fiber_id_out: *mut i32, panic_msg_out: *mut *const u8, panic_msg_len_out: *mut i32) -> i32:
    unsafe:
        *fiber_id_out = 0
        *panic_msg_out = 0 as *const u8
        *panic_msg_len_out = 0
    0

@[c_export("with_fiber_cleanup_await")]
pub fn fiber_cleanup_await(fiber_id: i32):
    let _ = fiber_id

@[c_export("with_runtime_request_cancel")]
pub fn runtime_request_cancel(fiber_id: i32) -> i32:
    let _ = fiber_id
    0

@[c_export("with_runtime_current_cancel_requested")]
pub fn runtime_current_cancel_requested() -> i32:
    0

@[c_export("with_runtime_current_set_cancel_requested")]
pub fn runtime_current_set_cancel_requested():
    let _ = 0

@[c_export("with_runtime_current_set_cancelled_return")]
pub fn runtime_current_set_cancelled_return():
    let _ = 0

@[c_export("with_runtime_completed_cancelled_return")]
pub fn runtime_completed_cancelled_return(fiber_id: i32) -> i32:
    let _ = fiber_id
    0

@[c_export("with_fiber_yield")]
pub fn fiber_yield():
    let _ = 0

@[c_export("with_runtime_has_fibers")]
pub fn runtime_has_fibers() -> i32:
    0

@[c_export("with_fiber_in_fiber")]
pub fn fiber_in_fiber() -> i32:
    0

@[c_export("with_fiber_panic_capture")]
pub fn fiber_panic_capture(msg: *const u8, msg_len: i32):
    let _ = msg
    let _ = msg_len
    abort()
