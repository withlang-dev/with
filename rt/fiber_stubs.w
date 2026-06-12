// rt/fiber_stubs.w -- non-async lifecycle/fiber fallback surface.
//
// Linked only when fiber.o is not present, so these can be strong definitions.

extern fn abort() -> Unit

pub fn with_runtime_init() -> Unit:
    let _ = 0

pub fn with_runtime_run() -> Unit:
    let _ = 0

pub fn with_runtime_shutdown() -> Unit:
    let _ = 0

pub fn with_runtime_run_one_step() -> Unit:
    let _ = 0

pub fn with_runtime_fiber_is_completed(fiber_id: i32) -> i32:
    let _ = fiber_id
    0

pub fn with_runtime_fiber_is_live(fiber_id: i32) -> i32:
    let _ = fiber_id
    0

pub unsafe fn with_runtime_take_completed_fiber(fiber_id: i32, panic_msg_out: *mut *const u8, panic_msg_len_out: *mut i32, cancelled_return_out: *mut i32) -> i32:
    let _ = fiber_id
    *panic_msg_out = 0 as *const u8
    *panic_msg_len_out = 0
    *cancelled_return_out = 0
    0

pub unsafe fn with_runtime_take_panicked_fiber(fiber_id_out: *mut i32, panic_msg_out: *mut *const u8, panic_msg_len_out: *mut i32) -> i32:
    *fiber_id_out = 0
    *panic_msg_out = 0 as *const u8
    *panic_msg_len_out = 0
    0

pub fn with_fiber_await(fiber_id: i32) -> Unit:
    let _ = fiber_id

pub fn with_fiber_cleanup_await(fiber_id: i32) -> Unit:
    let _ = fiber_id

pub fn with_fiber_cancel(fiber_id: i32) -> i32:
    let _ = fiber_id
    0

pub fn with_runtime_request_cancel(fiber_id: i32) -> i32:
    let _ = fiber_id
    0

pub fn with_fiber_detach_cancel(fiber_id: i32, result_buf: *mut u8) -> i32:
    let _ = fiber_id
    let _ = result_buf
    0

pub fn with_runtime_current_cancel_requested() -> i32:
    0

pub fn with_runtime_current_set_cancel_requested() -> Unit:
    let _ = 0

pub fn with_runtime_current_set_cancelled_return() -> Unit:
    let _ = 0

pub fn with_runtime_completed_cancelled_return(fiber_id: i32) -> i32:
    let _ = fiber_id
    0

pub fn with_fiber_yield() -> Unit:
    let _ = 0

pub fn with_runtime_has_fibers() -> i32:
    0

pub fn with_fiber_in_fiber() -> i32:
    0

pub fn with_fiber_panic_capture(msg: *const u8, msg_len: i32) -> Unit:
    let _ = msg
    let _ = msg_len
    abort()
