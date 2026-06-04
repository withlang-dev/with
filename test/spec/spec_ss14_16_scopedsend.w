//! expect-stdout: ok
// Spec test: Section 14.16 — ScopedSend (formerly 25.63)

async fn read_ref(value: &i32) -> i32:
    *value

fn test_scoped_worker_reads_local:
    let base = 40
    let result = scope s =>:
        let handle = s.spawn(() => base + 2)
        handle.join()
    assert(result == 42)

fn test_scoped_worker_mutates_local:
    var value = 40
    scope s =>
        let handle = s.spawn(() => { value = value + 2; 0 })
        let _ = handle.join()
    assert(value == 42)

fn test_scope_exit_joins_worker:
    var value = 1
    scope s =>:
        let handle = s.spawn(() => { value = 42; 0 })
    assert(value == 42)

async fn test_async_scope_tracks_borrowing_task:
    let value = 42
    let result =
        async scope s =>:
            let task = s.track(read_ref(&value))
            task.await
    assert(result == 42)

fn main:
    test_scoped_worker_reads_local()
    test_scoped_worker_mutates_local()
    test_scope_exit_joins_worker()
    test_async_scope_tracks_borrowing_task().await
    print("ok")
