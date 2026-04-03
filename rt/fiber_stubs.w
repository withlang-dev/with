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

@[c_export("with_fiber_yield")]
pub fn fiber_yield():
    let _ = 0

@[c_export("with_fiber_in_fiber")]
pub fn fiber_in_fiber() -> i32:
    0

@[c_export("with_fiber_is_cancelled")]
pub fn fiber_is_cancelled() -> i32:
    0

@[c_export("with_fiber_set_cancelled_return")]
pub fn fiber_set_cancelled_return():
    let _ = 0

@[c_export("with_fiber_was_cancelled_return")]
pub fn fiber_was_cancelled_return(fiber_id: i32) -> i32:
    let _ = fiber_id
    0

@[c_export("with_fiber_request_cancel_self")]
pub fn fiber_request_cancel_self():
    let _ = 0

@[c_export("with_fiber_panic_capture")]
pub fn fiber_panic_capture(msg: *const u8, msg_len: i32):
    let _ = msg
    let _ = msg_len
    abort()
