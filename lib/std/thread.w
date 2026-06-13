// std.thread — OS-thread facade.

@[effect(fn_ptr: escape_value, ctx: escape_value)]
extern fn with_thread_spawn(fn_ptr: *mut u8, ctx: *mut u8) -> i64
extern fn with_thread_join(handle: i64) -> i32

type RawFn0I32 {
    fn_ptr: *mut u8,
    ctx: *mut u8,
}

/// Handle to a spawned thread's result.
type JoinHandle  {
    handle: i64
}

/// Scope-owned OS-thread handle returned by `scope`'s `s.spawn(...)`.
pub type ScopedJoinHandle ephemeral {
    scope: i64,
    index: i32,
    handle: i64,
}

/// Spawn an OS thread running `worker`. Returns a JoinHandle.
@[effect(worker: escape_value)]
pub fn spawn_os(worker: fn() -> i32) -> JoinHandle:
    let raw: RawFn0I32 = unsafe transmute[RawFn0I32](worker)
    JoinHandle { handle: with_thread_spawn(raw.fn_ptr, raw.ctx) }

/// Wait for a thread to finish and return its result.
pub fn join(handle: JoinHandle) -> i32:
    with_thread_join(handle.handle)
