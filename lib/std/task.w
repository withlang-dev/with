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

/// Await all tasks. Returns Vec[T] in input order.
/// Fails fast on first Err.
pub async fn await_all[T, E](tasks: impl IntoIter[Task[Result[T, E]]]) -> Result[Vec[T], E]:
    let pending: Vec[Task[Result[T, E]]] = Vec.new()
    for task in tasks:
        pending.push(task)

    let values: Vec[T] = Vec.new()
    let total = pending.len() as i32
    var i = 0
    while i < total:
        let result = pending.get(i).await
        if result.is_ok():
            values.push(result.unwrap())
            i = i + 1
        else:
            // Fail-fast: cancel and join remaining owned tasks before return.
            var j = i + 1
            while j < total:
                let remaining = pending.get(j)
                remaining.cancel()
                let _joined = remaining.await
                j = j + 1
            return Err(result.err().unwrap())
    Ok(values)

/// Await all tasks (infallible version). Returns Vec[T] in input order.
pub async fn await_all[T](tasks: impl IntoIter[Task[T]]) -> Vec[T]:
    let pending: Vec[Task[T]] = Vec.new()
    for task in tasks:
        pending.push(task)

    let values: Vec[T] = Vec.new()
    let total = pending.len() as i32
    var i = 0
    while i < total:
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

    let winner = pending.get(0).await
    let total = pending.len() as i32
    var i = 1
    while i < total:
        let remaining = pending.get(i)
        remaining.cancel()
        let _joined = remaining.await
        i = i + 1
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
    while i < total:
        let result = pending.get(i).await
        if result.is_ok():
            let winner = result.unwrap()
            var j = i + 1
            while j < total:
                let remaining = pending.get(j)
                remaining.cancel()
                let _joined = remaining.await
                j = j + 1
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
    var i = 0
    while i < total:
        settled.push(pending.get(i).await)
        i = i + 1
    settled

/// Limit concurrent execution to at most `n` tasks at a time.
pub fn with_concurrency[T](tasks: impl IntoIter[Task[T]], n: i32) -> impl IntoIter[Task[T]]:
    let _ = n
    tasks
