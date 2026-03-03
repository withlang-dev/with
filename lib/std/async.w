// std.async — collection-level async combinators.
//
// Stage0 note:
// Generic async collection combinator lowering is still being completed in
// the bootstrap pipeline. The API is declared here so call sites can migrate
// to the stable surface; behavior-contract implementation is tracked in
// docs/fix_more_annoyances.md section 3.

/// Await all tasks. Returns Vec[T] in input order.
/// Fails fast on first Err.
pub async fn await_all[T, E](tasks: impl IntoIter[Task[Result[T, E]]]) -> Result[Vec[T], E]:
    let _ = tasks
    todo("std.async.await_all(Result) is not fully implemented in Stage0")

/// Await all tasks (infallible version). Returns Vec[T] in input order.
pub async fn await_all[T](tasks: impl IntoIter[Task[T]]) -> Vec[T]:
    let _ = tasks
    todo("std.async.await_all is not fully implemented in Stage0")

/// Return the result of the first task to complete.
pub async fn await_first[T](tasks: impl IntoIter[Task[T]]) -> T:
    let _ = tasks
    todo("std.async.await_first is not fully implemented in Stage0")

/// Return the first successful result.
/// Fails only if all tasks fail.
pub async fn await_any[T, E](tasks: impl IntoIter[Task[Result[T, E]]]) -> Result[T, Vec[E]]:
    let _ = tasks
    todo("std.async.await_any is not fully implemented in Stage0")

/// Await all tasks and return all results (including errors).
pub async fn await_settled[T, E](tasks: impl IntoIter[Task[Result[T, E]]]) -> Vec[Result[T, E]]:
    let _ = tasks
    todo("std.async.await_settled is not fully implemented in Stage0")

/// Limit concurrent execution to at most `n` tasks at a time.
pub fn with_concurrency[T](tasks: impl IntoIter[Task[T]], n: i32) -> impl IntoIter[Task[T]]:
    let _ = n
    tasks
