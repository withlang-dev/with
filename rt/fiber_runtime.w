// rt/fiber_runtime.w -- migrated fiber helpers that do not need direct context
// switching or queue ownership.

extern fn with_fiber_in_fiber() -> i32
extern fn with_fiber_yield() -> void
extern fn with_runtime_core_init() -> void
extern fn with_runtime_core_shutdown() -> void
extern fn with_runtime_core_has_fibers() -> i32
extern fn with_runtime_core_run_one_step() -> void
extern fn with_runtime_fiber_is_completed(fiber_id: i32) -> i32
extern fn with_runtime_take_completed_fiber(fiber_id: i32, panic_msg_out: *mut *const u8, panic_msg_len_out: *mut i32, cancelled_return_out: *mut i32) -> i32
extern fn with_runtime_take_panicked_fiber(fiber_id_out: *mut i32, panic_msg_out: *mut *const u8, panic_msg_len_out: *mut i32) -> i32
extern fn with_runtime_request_cancel(fiber_id: i32) -> i32
extern fn with_runtime_current_cancel_requested() -> i32
extern fn with_runtime_current_set_cancel_requested() -> void
extern fn with_runtime_current_set_cancelled_return() -> void
extern fn with_runtime_completed_cancelled_return(fiber_id: i32) -> i32
extern fn with_ewrite(s: str) -> void
extern fn with_i64_to_str(n: i64) -> str
extern fn _exit(code: i32) -> void
extern fn abort() -> void

type RawStr:
    ptr: *const u8
    len: i64

fn make_str(ptr: *const u8, len: i64) -> str:
    let raw = RawStr { ptr: ptr, len: len }
    let p = &raw as *const str
    unsafe *p

var last_await_fiber_id: i32 = 0
var last_await_cancelled_return: i32 = 0

fn fiber_report_unhandled_panics() -> i32:
    var had_unhandled = 0
    while true:
        var fiber_id: i32 = 0
        var panic_msg: *const u8 = 0 as *const u8
        var panic_msg_len: i32 = 0
        if with_runtime_take_panicked_fiber(
            &raw mut fiber_id as *mut i32,
            &raw mut panic_msg as *mut *const u8,
            &raw mut panic_msg_len as *mut i32
        ) == 0:
            return had_unhandled

        had_unhandled = 1
        with_ewrite("unhandled panic in fiber #")
        with_ewrite(with_i64_to_str(fiber_id as i64))
        with_ewrite(": ")
        if panic_msg as i64 != 0 and panic_msg_len > 0:
            with_ewrite(make_str(panic_msg, panic_msg_len as i64))
        else:
            with_ewrite("(null)")
        with_ewrite("\n")

@[c_export("with_runtime_init")]
pub fn runtime_init():
    with_runtime_core_init()

@[c_export("with_runtime_shutdown")]
pub fn runtime_shutdown():
    with_runtime_core_shutdown()

@[c_export("with_runtime_has_fibers")]
pub fn runtime_has_fibers() -> i32:
    with_runtime_core_has_fibers()

@[c_export("with_runtime_run_one_step")]
pub fn runtime_run_one_step():
    with_runtime_core_run_one_step()

@[c_export("with_runtime_run")]
pub fn runtime_run():
    while with_runtime_core_has_fibers() != 0:
        with_runtime_core_run_one_step()

    if fiber_report_unhandled_panics() != 0:
        _exit(1)

@[c_export("with_fiber_select")]
pub fn fiber_select(fiber_ids: *const i32, count: i32, result_index: *mut i32):
    while true:
        var i = 0
        while i < count:
            let fid = unsafe *((fiber_ids as i64 + i as i64 * 4) as *const i32)
            if with_runtime_fiber_is_completed(fid) != 0:
                unsafe:
                    *result_index = i
                return
            i = i + 1

        if with_fiber_in_fiber() != 0:
            with_fiber_yield()
        else if with_runtime_core_has_fibers() != 0:
            with_runtime_core_run_one_step()
        else:
            unsafe:
                *result_index = -1
            return

@[c_export("with_fiber_await")]
pub fn fiber_await(fiber_id: i32):
    while true:
        var panic_msg: *const u8 = 0 as *const u8
        var panic_msg_len: i32 = 0
        var cancelled_return: i32 = 0
        if with_runtime_take_completed_fiber(fiber_id, &raw mut panic_msg as *mut *const u8, &raw mut panic_msg_len as *mut i32, &raw mut cancelled_return as *mut i32) != 0:
            last_await_fiber_id = fiber_id
            last_await_cancelled_return = cancelled_return
            if panic_msg as i64 != 0 and panic_msg_len > 0:
                with_ewrite(make_str(panic_msg, panic_msg_len as i64))
                with_ewrite("\n")
                abort()
            return

        if with_fiber_in_fiber() != 0:
            if with_runtime_current_cancel_requested() != 0:
                last_await_fiber_id = fiber_id
                last_await_cancelled_return = 0
                return
            with_fiber_yield()
        else if with_runtime_core_has_fibers() != 0:
            with_runtime_core_run_one_step()
        else:
            last_await_fiber_id = fiber_id
            last_await_cancelled_return = 0
            return

@[c_export("with_fiber_cleanup_await")]
pub fn fiber_cleanup_await(fiber_id: i32):
    while true:
        var panic_msg: *const u8 = 0 as *const u8
        var panic_msg_len: i32 = 0
        var cancelled_return: i32 = 0
        if with_runtime_take_completed_fiber(fiber_id, &raw mut panic_msg as *mut *const u8, &raw mut panic_msg_len as *mut i32, &raw mut cancelled_return as *mut i32) != 0:
            last_await_fiber_id = fiber_id
            last_await_cancelled_return = cancelled_return
            if panic_msg as i64 != 0 and panic_msg_len > 0:
                with_ewrite(make_str(panic_msg, panic_msg_len as i64))
                with_ewrite("\n")
                abort()
            return

        if with_fiber_in_fiber() != 0:
            with_fiber_yield()
        else if with_runtime_core_has_fibers() != 0:
            with_runtime_core_run_one_step()
        else:
            last_await_fiber_id = fiber_id
            last_await_cancelled_return = 0
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
    if last_await_fiber_id == fiber_id:
        return last_await_cancelled_return
    with_runtime_completed_cancelled_return(fiber_id)

@[c_export("with_fiber_request_cancel_self")]
pub fn fiber_request_cancel_self():
    with_runtime_current_set_cancel_requested()
