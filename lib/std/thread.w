// std.thread — OS-thread facade.
//
// Current implementation runs work eagerly and returns a join handle.

/// Handle to a spawned thread's result.
type JoinHandle  {
    result: i32
}

/// Spawn an OS thread running `worker`. Returns a JoinHandle.
pub fn spawn_os(worker: fn() -> i32) -> JoinHandle:
    JoinHandle { result: worker() }

/// Wait for a thread to finish and return its result.
pub fn join(handle: JoinHandle) -> i32:
    handle.result
