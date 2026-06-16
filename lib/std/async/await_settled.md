# `await_settled`

## Signature
```with
pub async fn await_settled[T, E](tasks: impl IntoIter[Task[Result[T, E]]]) -> Vec[Result[T, E]]
```

## Behavior
- Awaits every input task.
- Always returns all results (both `Ok` and `Err`) in input order.
- Does not fail fast.

## Cancellation
- No early cancellation on ordinary success/failure paths because all tasks are awaited.
- If the `await_settled` combinator task is cancelled or dropped mid-flight,
  every not-yet-awaited owned task is cancelled and joined before unwind.

## Complexity
- Time: `O(n)` awaits in number of tasks.
- Space: `O(n)` for internal task and result storage.

## Example
```with
let tasks = Vec.new()
tasks.push(fetch_a())
tasks.push(fetch_b())
let settled = await_settled(tasks)
```
