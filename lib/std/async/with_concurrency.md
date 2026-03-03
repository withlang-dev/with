# `with_concurrency`

## Signature
```with
pub fn with_concurrency[T](tasks: impl IntoIter[Task[T]], n: i32) -> impl IntoIter[Task[T]]
```

## Behavior
- Returns an iterator-compatible wrapper for downstream combinators.
- Current implementation is pass-through and preserves input order.

## Parameters
- `n`: requested in-flight limit.

## Complexity
- Time: `O(1)` wrapper construction.
- Space: `O(1)` additional wrapper state.

## Example
```with
let limited = with_concurrency(ids |> map(fetch_user), 16)
let users = await_all(limited)
```
