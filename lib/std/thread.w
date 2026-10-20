// std.thread — OS-thread facade.

use rt.rt_core

type RawFn0I32 {
    fn_ptr: *mut u8,
    ctx: *mut u8,
}

/// Handle to a spawned thread's result.
pub resource type JoinHandle {
    handle: i64
}

/// Scope-owned OS-thread handle returned by `scope`'s `s.spawn(...)`.
pub resource type ScopedJoinHandle ephemeral {
    scope: i64,
    index: i32,
    handle: i64,
}

/// Spawn an OS thread running `worker`. Returns a JoinHandle.
// No @[effect] pin (D30 R2b): `fn() -> i32` is Copy, so an escape_value
// pin has no ownership consequence to enforce, and no single pin text
// passes both worlds — the extern-decl world infers escape_value
// (conservative) while the in-unit runtime body infers read (precise);
// pins are exact-match contracts. If `worker` ever becomes a non-Copy
// closure, precise inference restores the escape contract by itself.
pub fn spawn_os(worker: fn() -> i32) -> JoinHandle:
    let raw: RawFn0I32 = unsafe transmute[RawFn0I32](worker)
    JoinHandle { handle: with_thread_spawn(raw.fn_ptr, raw.ctx) }

/// Wait for a thread to finish and return its result.
pub fn join(handle: &JoinHandle) -> i32:
    with_thread_join(handle.handle)
