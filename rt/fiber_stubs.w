// rt/fiber_stubs.w -- non-async lifecycle/fiber fallback surface.
//
// Linked only when fiber.o is not present, so these can be strong definitions.

@[link_name("abort")]
extern fn rt_libc_abort() -> Unit
extern fn with_debug_alloc_report_leaks() -> Unit
extern fn rt_write(fd: i32, buf: *const u8, len: i64) -> i64

pub fn with_runtime_init():
    let _ = 0

pub fn with_runtime_run():
    let _ = 0

pub fn with_runtime_shutdown():
    with_debug_alloc_report_leaks()

pub fn with_runtime_run_one_step():
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

pub fn with_fiber_await(fiber_id: i32):
    let _ = fiber_id

pub fn with_fiber_cleanup_await(fiber_id: i32):
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

pub fn with_runtime_current_set_cancel_requested():
    let _ = 0

pub fn with_runtime_current_set_cancelled_return():
    let _ = 0

pub fn with_runtime_current_cancelled_return() -> i32:
    0

pub fn with_runtime_completed_cancelled_return(fiber_id: i32) -> i32:
    let _ = fiber_id
    0

pub fn with_fiber_yield():
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

pub fn with_fiber_panic_capture(msg: *const u8, msg_len: i32):
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
// The process state POSIX.1-2017 names beyond the C library's (#1608,
// refinements under ruling §35): a row preserves each unless its function
// is one of the interfaces POSIX names as altering it.
//   signals     (process) — dispositions: sigaction; raise, kill and abort
//                           deliver a signal, so they are counted too.
//   signal_mask (thread)  — the calling thread's mask and alternate stack:
//                           sigprocmask, sigaltstack.
//   cwd         (process) — the working directory: chdir.
//   fds         (process) — the descriptor table: open, close, dup2, fcntl,
//                           socket, accept, mkstemp, opendir, closedir;
//                           getaddrinfo and realpath may open descriptors
//                           of their own, and exec closes close-on-exec ones.
//   rlimits     (process) — setrlimit.
//   children    (process) — the children and process group: fork, waitpid,
//                           wait4, setpgid, exec.
//   stdio       (process) — the streams' buffers and positions: fseeko
//                           (fileno, ftello and isatty only read them).
// No safe view depends on them yet; the rows make a runtime call that
// begins altering one visible to the audit (§52).
c facade libc:
    domain errno thread
    domain environ process
    domain locale process
    domain signals process
    domain signal_mask thread
    domain cwd process
    domain fds process
    domain rlimits process
    domain children process
    domain stdio process
    fn rt_libc_abort
        preserves domain environ
        preserves domain locale
        preserves domain signal_mask
        preserves domain cwd
        preserves domain fds
        preserves domain rlimits
        preserves domain children
        preserves domain stdio

// D69 (#1748): `g.pull()` steps a generator on its own fiber through these.
// A program linked without the fiber runtime has none to step it on; the
// std.task definitions still reference them, so each is defined here and
// stops the program loudly instead of pretending to step.
fn with_fiber_coro_unavailable() -> Never:
    let _ = rt_write(2, "fatal: a generator's pull() needs the fiber runtime, which this program was linked without\n" as *const u8, 91)
    rt_libc_abort()
    loop:
        let _ = 0

pub fn with_fiber_coro_new(entry: *const u8, arg: *mut u8) -> i64:
    let _ = entry
    let _ = arg
    with_fiber_coro_unavailable()

pub fn with_fiber_coro_resume(co: i64):
    let _ = co
    with_fiber_coro_unavailable()

pub fn with_fiber_coro_suspend(co: i64):
    let _ = co
    with_fiber_coro_unavailable()

pub fn with_fiber_coro_finish(co: i64):
    let _ = co
    with_fiber_coro_unavailable()

pub fn with_fiber_coro_free(co: i64):
    let _ = co
    with_fiber_coro_unavailable()
