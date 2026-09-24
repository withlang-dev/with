// rt/fiber_stubs.w -- non-async lifecycle/fiber fallback surface.
//
// Linked only when fiber.o is not present, so these can be strong definitions.

@[link_name("abort")]
extern fn rt_libc_abort() -> Unit
extern fn with_debug_alloc_report_leaks() -> Unit

pub fn with_runtime_init() -> Unit:
    let _ = 0

pub fn with_runtime_run() -> Unit:
    let _ = 0

pub fn with_runtime_shutdown() -> Unit:
    with_debug_alloc_report_leaks()

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

pub fn with_fiber_detach(fiber_id: i32, result_buf: *mut u8) -> i32:
    let _ = fiber_id
    let _ = result_buf
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

pub fn with_runtime_current_cancelled_return() -> i32:
    0

pub fn with_runtime_completed_cancelled_return(fiber_id: i32) -> i32:
    let _ = fiber_id
    0

pub fn with_fiber_yield() -> Unit:
    let _ = 0

pub fn with_runtime_has_fibers() -> i32:
    0

pub fn with_fiber_in_fiber() -> i32:
    0

pub fn with_fiber_steal_events() -> i64:
    0

pub fn with_fiber_steal_attempts() -> i64:
    0

pub fn with_fiber_worker_count() -> i32:
    1

pub fn with_fiber_current_worker_index() -> i32:
    0

pub fn with_fiber_cross_thread_cancels() -> i64:
    0

pub fn with_runtime_fiber_running_worker(fiber_id: i32) -> i32:
    let _ = fiber_id
    -1

pub fn with_fiber_panic_capture(msg: *const u8, msg_len: i32) -> Unit:
    let _ = msg
    let _ = msg_len
    rt_libc_abort()

// ── Foreign-state domain rows (ruling §52, spec §16.2b.14) ────────────────
// The runtime is not exempt from the foreign-state model: every foreign
// call above is described here, and the `runtime-domain-audit` lane
// (build/compiler.w) refuses a foreign extern without a row. A row states
// the view effect of the call on each domain the C library owns; "unknown
// effect means invalidate" (§38), so a row that says nothing invalidates.
// `preserves` appears only where the C standard says so:
//   errno   (thread)  — C11 7.5p3: any library function may set errno, so
//                       no call preserves it; the errno accessor is the
//                       macro's lvalue itself (7.5p2) and preserves it.
//   environ (process) — C11 7.22.4.6: altering the environment list is the
//                       implementation's method — POSIX.1-2017 setenv,
//                       unsetenv, putenv — and getenv may overwrite the
//                       text it returned (XSH getenv); those rows do not
//                       preserve it, every other call does.
//   locale  (process) — C11 7.11.1.1: setlocale is the function that
//                       changes the locale; the runtime never calls it.
c facade libc:
    domain errno thread
    domain environ process
    domain locale process
    fn rt_libc_abort
        preserves domain environ
        preserves domain locale
