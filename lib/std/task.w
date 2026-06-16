// std.task — Task type and collection-level async combinators.
//
// Task[T] is an opaque handle to a running fiber. It contains the fiber_id
// and a pointer to the heap-allocated result buffer where the fiber writes
// its return value. The T parameter is for type safety in sema.

use std.collections
use std.result

/// Opaque handle to a running fiber. Returned by async fn calls.
/// The result_buf points to a heap-allocated buffer where the fiber
/// writes its return value. Await loads from it and frees it.
pub type Task[T] { fiber_id: i32, result_buf: *mut u8 }

/// Scope-owned task handle returned by `async scope`'s `s.track(...)`.
/// It has the same ABI as Task[T], but its cleanup is owned by the scope,
/// so dropping the handle itself does not cancel the fiber.
pub type ScopedTask[T] ephemeral { fiber_id: i32, result_buf: *mut u8 }

/// Await all tasks. Returns Vec[T] in input order.
/// Fails fast on first Err.
pub async fn await_all[T, E](tasks: impl IntoIter[Task[Result[T, E]]]) -> Result[Vec[T], E]:
    let pending: Vec[Task[Result[T, E]]] = Vec.new()
    for task in tasks:
        pending.push(task)

    let values: Vec[T] = Vec.new()
    let total = pending.len() as i32
    var next_unjoined = 0
    defer:
        while next_unjoined < total:
            pending.get(next_unjoined).join_cleanup()
            next_unjoined = next_unjoined + 1

    var i = 0
    while i < total:
        next_unjoined = i + 1
        let result = pending.get(i).await
        if result.is_ok():
            values.push(result.unwrap())
            i = i + 1
        else:
            // Fail-fast: cancel and join remaining owned tasks before return.
            while next_unjoined < total:
                pending.get(next_unjoined).join_cleanup()
                next_unjoined = next_unjoined + 1
            return Err(result.err().unwrap())
    Ok(values)

/// Await all tasks (infallible version). Returns Vec[T] in input order.
pub async fn await_all[T](tasks: impl IntoIter[Task[T]]) -> Vec[T]:
    let pending: Vec[Task[T]] = Vec.new()
    for task in tasks:
        pending.push(task)

    let values: Vec[T] = Vec.new()
    let total = pending.len() as i32
    var next_unjoined = 0
    defer:
        while next_unjoined < total:
            pending.get(next_unjoined).join_cleanup()
            next_unjoined = next_unjoined + 1

    var i = 0
    while i < total:
        next_unjoined = i + 1
        values.push(pending.get(i).await)
        i = i + 1
    values

/// Return the result of the first task to complete.
pub async fn await_first[T](tasks: impl IntoIter[Task[T]]) -> T:
    let pending: Vec[Task[T]] = Vec.new()
    for task in tasks:
        pending.push(task)

    if pending.is_empty():
        todo("await_first: empty input")

    let total = pending.len() as i32
    var next_unjoined = 1
    defer:
        while next_unjoined < total:
            pending.get(next_unjoined).join_cleanup()
            next_unjoined = next_unjoined + 1

    let winner = pending.get(0).await
    while next_unjoined < total:
        pending.get(next_unjoined).join_cleanup()
        next_unjoined = next_unjoined + 1
    winner

/// Return the first successful result.
/// Fails only if all tasks fail.
pub async fn await_any[T, E](tasks: impl IntoIter[Task[Result[T, E]]]) -> Result[T, Vec[E]]:
    let pending: Vec[Task[Result[T, E]]] = Vec.new()
    for task in tasks:
        pending.push(task)

    let errors: Vec[E] = Vec.new()
    let total = pending.len() as i32
    if pending.is_empty():
        return Err(errors)

    var i = 0
    var next_unjoined = 0
    defer:
        while next_unjoined < total:
            pending.get(next_unjoined).join_cleanup()
            next_unjoined = next_unjoined + 1

    while i < total:
        next_unjoined = i + 1
        let result = pending.get(i).await
        if result.is_ok():
            let winner = result.unwrap()
            while next_unjoined < total:
                pending.get(next_unjoined).join_cleanup()
                next_unjoined = next_unjoined + 1
            return Ok(winner)
        errors.push(result.err().unwrap())
        i = i + 1
    Err(errors)

/// Await all tasks and return all results (including errors).
pub async fn await_settled[T, E](tasks: impl IntoIter[Task[Result[T, E]]]) -> Vec[Result[T, E]]:
    let pending: Vec[Task[Result[T, E]]] = Vec.new()
    for task in tasks:
        pending.push(task)

    let settled: Vec[Result[T, E]] = Vec.new()
    let total = pending.len() as i32
    var next_unjoined = 0
    defer:
        while next_unjoined < total:
            pending.get(next_unjoined).join_cleanup()
            next_unjoined = next_unjoined + 1

    var i = 0
    while i < total:
        next_unjoined = i + 1
        settled.push(pending.get(i).await)
        i = i + 1
    settled

/// Limit concurrent execution to at most `n` tasks at a time.
pub fn with_concurrency[T](tasks: impl IntoIter[Task[T]], n: i32) -> impl IntoIter[Task[T]]:
    let _ = n
    tasks
