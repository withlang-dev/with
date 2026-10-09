# `await_all`

## Signatures
```with
pub async fn await_all[T, E](tasks: impl IntoIter[Task[Result[T, E]]]) -> Result[List[T], E]
pub async fn await_all[T](tasks: impl IntoIter[Task[T]]) -> List[T]
```

## Behavior
- Awaits every input task and collects results in input order.
- **Fallible overload** (`Result` tasks): returns `Ok(List[T])` when all tasks succeed. On first `Err`, cancels remaining tasks and returns that error immediately (fail-fast).
- **Infallible overload** (plain tasks): awaits all tasks and returns `List[T]`.

## Empty input
- `await_all([])` returns `Ok(List.new())` (fallible) or `List.new()` (infallible).

## Cancellation
- Fallible overload: on first error, remaining owned tasks are cancelled and joined before return.
- Infallible overload: no early cancellation; all tasks are awaited.
- If the `await_all` combinator task is cancelled or dropped mid-flight,
  every not-yet-awaited owned task is cancelled and joined before unwind.

## Complexity
- Time: `O(n)` awaits in number of tasks.
- Space: `O(n)` due to internal task materialization plus result collection.

## Example
```with
let tasks = List.new()
tasks.push(fetch_user(1))
tasks.push(fetch_user(2))
tasks.push(fetch_user(3))
let users = await_all(tasks)
```

Pipeline style:
```with
let users = ids |> map(fetch_user) |> await_all
```
