# `std.async`

Collection await combinators for `Task[...]` values.

## Public API
- `await_all[T](tasks: impl IntoIter[Task[T]]) -> Vec[T]`
- `await_all[T, E](tasks: impl IntoIter[Task[Result[T, E]]]) -> Result[Vec[T], E]`
- `await_first[T](tasks: impl IntoIter[Task[T]]) -> T`
- `await_any[T, E](tasks: impl IntoIter[Task[Result[T, E]]]) -> Result[T, Vec[E]]`
- `await_settled[T, E](tasks: impl IntoIter[Task[Result[T, E]]]) -> Vec[Result[T, E]]`
- `with_concurrency[T](tasks: impl IntoIter[Task[T]], n: i32) -> impl IntoIter[Task[T]]`

## Guarantees
- Ordering:
  `await_all` and `await_settled` return results in input order.
- Empty input:
  `await_first([])` panics with message `await_first: empty input`.
  `await_any([])` returns `Err(Vec.new())`.
- Error aggregation:
  `await_any` returns all errors in input order when all tasks fail.

## Cancellation model
- `await_all(Result)`: fail-fast on first `Err`, then cancel/join remaining owned tasks.
- `await_first`: once one result is chosen, cancel/join remaining owned tasks.
- `await_any`: once one `Ok` is chosen, cancel/join remaining owned tasks.

## Iterator consumption
- Inputs are consumed exactly once and materialized into an internal `Vec` before awaiting.
- This is eager consumption (not streaming); memory is `O(n)` in number of tasks.
