# `with_concurrency`

## Signature
```with
pub fn with_concurrency[I, T](inputs: impl IntoIter[I], n: isize, f: fn(I) -> Task[T]) -> List[T]
```

## Behavior
- Runs `f` over `inputs` with at most `n` of the tasks it starts running at once.
- Returns the results in input order, however the tasks finish.
- The limiter starts the work itself: a `Task` is already running, so a
  limiter handed tasks could bound nothing. `f(input)` is called — and
  spawns — only when a slot frees.
- `n` must be at least 1.

## Parameters
- `n`: the in-flight limit, at least 1.
- `f`: the async work, one task per input.

## Complexity
- Time: `O(n)` per completion scan, `O(inputs * n)` overall.
- Space: `O(inputs)` for the results, `O(n)` live tasks.

## Example
```with
let users = ids |> with_concurrency(16, fetch_user)
```
