// std.thread — OS-thread façade for bootstrap.
//
// Current bootstrap implementation runs work eagerly and returns a join handle.

type JoinHandle = {
    result: i32
}

pub fn spawn_os(worker: fn() -> i32) -> JoinHandle =
    JoinHandle { result: worker() }

pub fn join(handle: JoinHandle) -> i32 =
    handle.result
