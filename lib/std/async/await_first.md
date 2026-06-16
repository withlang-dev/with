# `await_first`

## Signature
```with
pub async fn await_first[T](tasks: impl IntoIter[Task[T]]) -> T
```

## Behavior
- Consumes all input tasks once.
- Returns one task result and then tears down the rest.

## Empty input
- `await_first([])` panics with message:
  `await_first: empty input`

## Cancellation
- After choosing a result, remaining owned tasks are cancelled and joined before return.
- If the `await_first` combinator task is cancelled or dropped mid-flight,
  every not-yet-awaited owned task is cancelled and joined before unwind.

## Complexity
- Time: `O(n)` in number of tasks.
- Space: `O(n)` due to internal task materialization.

## Example
```with
let tasks = Vec.new()
tasks.push(fetch_primary())
tasks.push(fetch_fallback())
let winner = await_first(tasks)
```
