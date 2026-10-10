# 24. `async`/`.await` Equivalences

### 24.1 `async fn` Equivalence

`async fn foo(x: T) -> U: body` is equivalent to a function that
spawns a fiber executing `body` and returns a `Task[U]`:

```
fn foo(x: T) -> Task[U]
```

There is no separate "async function type." `foo` is a regular
function that returns `Task[U]`. This is why Invariant 1 (no async
function type) holds.

### 24.2 `.await` Equivalence

`task.await` suspends the current fiber until `task` completes,
then evaluates to the task's result. If the task is already complete,
no suspension occurs.

### 24.3 `no_runtime` Gate

In `no_runtime` builds, any occurrence of `async fn`, `.await`, or
`async scope` is a **compile error**. This is a hard gate, not a
runtime fallback.

---
