// rt/fiber_runtime.w -- migrated fiber helpers that do not need direct context
// switching or queue ownership.

extern fn with_fiber_in_fiber() -> i32
extern fn with_fiber_yield() -> void
extern fn with_runtime_core_init() -> void
extern fn with_runtime_core_shutdown() -> void
extern fn with_runtime_core_has_fibers() -> i32
extern fn with_runtime_core_run_one_step() -> void
extern fn with_runtime_fiber_is_completed(fiber_id: i32) -> i32
extern fn with_runtime_fiber_is_live(fiber_id: i32) -> i32
extern fn with_runtime_take_completed_fiber(fiber_id: i32, panic_msg_out: *mut *const u8, panic_msg_len_out: *mut i32, cancelled_return_out: *mut i32) -> i32
extern fn with_runtime_take_panicked_fiber(fiber_id_out: *mut i32, panic_msg_out: *mut *const u8, panic_msg_len_out: *mut i32) -> i32
extern fn with_runtime_request_cancel(fiber_id: i32) -> i32
extern fn with_runtime_current_cancel_requested() -> i32
extern fn with_runtime_current_set_cancel_requested() -> void
extern fn with_runtime_current_set_cancelled_return() -> void
extern fn with_runtime_completed_cancelled_return(fiber_id: i32) -> i32
extern fn with_free(ptr: *mut u8) -> void
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
var select_rng_state: u32 = 1 as u32
let MAX_DETACHED_FIBERS: i32 = 1024
var detached_fiber_ids: [1024]i32 = [0 as i32; 1024]
var detached_result_bufs: [1024]i64 = [0 as i64; 1024]
var detached_fiber_count: i32 = 0

fn select_next_u32() -> u32:
    select_rng_state = (select_rng_state *% (1664525 as u32)) +% (1013904223 as u32)
    select_rng_state

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

pub fn with_runtime_init() -> void:
    with_runtime_core_init()

pub fn with_runtime_shutdown() -> void:
    fiber_drain_detached_ready()
    fiber_clear_detached_buffers()
    with_runtime_core_shutdown()

pub fn with_runtime_has_fibers() -> i32:
    with_runtime_core_has_fibers()

pub fn with_runtime_run_one_step() -> void:
    with_runtime_core_run_one_step()
    fiber_drain_detached_ready()

pub fn with_runtime_run() -> void:
    while with_runtime_core_has_fibers() != 0:
        with_runtime_core_run_one_step()
        fiber_drain_detached_ready()
    fiber_drain_detached_ready()

    if fiber_report_unhandled_panics() != 0:
        _exit(1)

fn fiber_take_detached_completed(fiber_id: i32, result_buf: *mut u8) -> i32:
    var panic_msg: *const u8 = 0 as *const u8
    var panic_msg_len: i32 = 0
    var cancelled_return: i32 = 0
    if with_runtime_take_completed_fiber(fiber_id, &raw mut panic_msg as *mut *const u8, &raw mut panic_msg_len as *mut i32, &raw mut cancelled_return as *mut i32) == 0:
        return 0
    let _ = cancelled_return
    if result_buf as i64 != 0:
        with_free(result_buf)
    if panic_msg as i64 != 0 and panic_msg_len > 0:
        with_ewrite(make_str(panic_msg, panic_msg_len as i64))
        with_ewrite("\n")
        abort()
    1

fn fiber_remove_detached_at(index: i32):
    if index < 0 or index >= detached_fiber_count:
        return
    detached_fiber_count = detached_fiber_count - 1
    if index != detached_fiber_count:
        detached_fiber_ids[index as i64] = detached_fiber_ids[detached_fiber_count as i64]
        detached_result_bufs[index as i64] = detached_result_bufs[detached_fiber_count as i64]
    detached_fiber_ids[detached_fiber_count as i64] = 0
    detached_result_bufs[detached_fiber_count as i64] = 0

fn fiber_drain_detached_ready():
    var i = 0
    while i < detached_fiber_count:
        let fid = detached_fiber_ids[i as i64]
        let rbuf = detached_result_bufs[i as i64] as *mut u8
        if fiber_take_detached_completed(fid, rbuf) != 0:
            fiber_remove_detached_at(i)
        else:
            i = i + 1

fn fiber_clear_detached_buffers():
    var i = 0
    while i < detached_fiber_count:
        let rbuf = detached_result_bufs[i as i64] as *mut u8
        if rbuf as i64 != 0:
            with_free(rbuf)
        detached_fiber_ids[i as i64] = 0
        detached_result_bufs[i as i64] = 0
        i = i + 1
    detached_fiber_count = 0

unsafe fn fiber_select_ready_index(fiber_ids: *const i32, count: i32, biased: i32) -> i32:
    var chosen = -1
    var ready_seen = 0
    var i = 0
    while i < count:
        let fid = *((fiber_ids as i64 + i as i64 * 4) as *const i32)
        if with_runtime_fiber_is_completed(fid) != 0:
            if biased != 0:
                return i
            ready_seen = ready_seen + 1
            if chosen < 0:
                chosen = i
            else if (select_next_u32() % (ready_seen as u32)) == 0 as u32:
                chosen = i
        i = i + 1
    chosen

pub unsafe fn with_fiber_select_mode(fiber_ids: *const i32, count: i32, biased: i32, result_index: *mut i32) -> void:
    while true:
        let selected = fiber_select_ready_index(fiber_ids, count, biased)
        if selected >= 0:
            *result_index = selected
            return

        if with_fiber_in_fiber() != 0:
            with_fiber_yield()
        else if with_runtime_core_has_fibers() != 0:
            with_runtime_core_run_one_step()
        else:
            *result_index = -1
            return

pub unsafe fn with_fiber_select(fiber_ids: *const i32, count: i32, result_index: *mut i32) -> void:
    with_fiber_select_mode(fiber_ids, count, 0, result_index)

pub fn with_fiber_await(fiber_id: i32) -> void:
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
        if with_runtime_fiber_is_live(fiber_id) == 0:
            last_await_fiber_id = fiber_id
            last_await_cancelled_return = 0
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

pub fn with_fiber_cleanup_await(fiber_id: i32) -> void:
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
        if with_runtime_fiber_is_live(fiber_id) == 0:
            last_await_fiber_id = fiber_id
            last_await_cancelled_return = 0
            return

        if with_fiber_in_fiber() != 0:
            with_fiber_yield()
        else if with_runtime_core_has_fibers() != 0:
            with_runtime_core_run_one_step()
        else:
            last_await_fiber_id = fiber_id
            last_await_cancelled_return = 0
            return

pub fn with_fiber_cancel(fiber_id: i32) -> i32:
    if with_runtime_fiber_is_completed(fiber_id) != 0:
        return 1
    with_runtime_request_cancel(fiber_id)

pub fn with_fiber_detach_cancel(fiber_id: i32, result_buf: *mut u8) -> i32:
    if fiber_id <= 0:
        if result_buf as i64 != 0:
            with_free(result_buf)
        return 0
    if fiber_take_detached_completed(fiber_id, result_buf) != 0:
        return 1
    let requested = with_runtime_request_cancel(fiber_id)
    if fiber_take_detached_completed(fiber_id, result_buf) != 0:
        return 1
    if requested == 0:
        if result_buf as i64 != 0:
            with_free(result_buf)
        return 0
    fiber_drain_detached_ready()
    if detached_fiber_count >= MAX_DETACHED_FIBERS:
        with_ewrite("fatal: too many detached fibers\n")
        abort()
    detached_fiber_ids[detached_fiber_count as i64] = fiber_id
    detached_result_bufs[detached_fiber_count as i64] = result_buf as i64
    detached_fiber_count = detached_fiber_count + 1
    1

pub fn with_fiber_is_cancelled() -> i32:
    with_runtime_current_cancel_requested()

pub fn with_fiber_set_cancelled_return() -> void:
    with_runtime_current_set_cancelled_return()

pub fn with_fiber_was_cancelled_return(fiber_id: i32) -> i32:
    if last_await_fiber_id == fiber_id:
        return last_await_cancelled_return
    with_runtime_completed_cancelled_return(fiber_id)

pub fn with_fiber_request_cancel_self() -> void:
    with_runtime_current_set_cancel_requested()
