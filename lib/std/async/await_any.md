# `await_any`

## Signature
```with
pub async fn await_any[T, E](tasks: impl IntoIter[Task[Result[T, E]]]) -> Result[T, Vec[E]]
```

## Behavior
- Returns `Ok(T)` once one successful result is found.
- If all tasks fail, returns `Err(Vec[E])`.
- Error vector order for all-fail is input order.

## Empty input
- `await_any([])` returns `Err(Vec.new())`.

## Cancellation
- On first success, remaining owned tasks are cancelled and joined before return.
- If the `await_any` combinator task is cancelled or dropped mid-flight,
  every not-yet-awaited owned task is cancelled and joined before unwind.

## Complexity
- Time: `O(n)` awaits in number of tasks.
- Space: `O(n)` due to internal task materialization plus error collection.

## Example
```with
let tasks = Vec.new()
tasks.push(query_a())
tasks.push(query_b())
let result = await_any(tasks)
```
