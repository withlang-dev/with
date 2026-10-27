# D164 — `with_concurrency` starts the work itself: `(inputs, n, f) -> List[T]`, at most `n` of its tasks running at once (delegated)

**Laws:** 2, 7 (docs/mission.md) — a documented limit that does nothing
is the forbidden silent fallback.

**Date:** 2026-10-26. **Status:** delegated (D98): implemented on the
prediction below; Eric vetoes by revert. **Issue:** #981.

**Decision.** `std.task.with_concurrency[I, T](inputs: impl IntoIter[I],
n: isize, f: fn(I) -> Task[T]) -> List[T]` runs `f` over the inputs with
at most `n` (at least 1; less is a loud refusal) of the tasks it starts
running at once and returns their results in input order:
`ids |> with_concurrency(10, fetch_user)`. The old signature
(`(tasks, n: i32) -> impl IntoIter[Task[T]]`, body `let _ = n; tasks`)
is deleted; its call did not compile, and no task-taking signature can
mean what the doc said, because a `Task` is already running (§24.1).

**Context.** Measured on the task-taking draft: `ids |> map(f)` over a
`List` starts every task before a limiter downstream can pull one (peak
6 under limits 2 and 1), and the lazy adapter spelling does not
type-check into `impl IntoIter[Task[T]]` today. A task-taking limiter
would therefore silently not limit under its documented spelling. With
fn values spawning like direct calls (#2748), a limiter that calls
`f(input)` only when a slot frees can actually bound what runs.

**What the others do.** Rust futures `buffer_unordered(n)`/`buffered(n)`
pull lazily from a stream of not-yet-started futures; Swift
`withTaskGroup` adds tasks as earlier ones finish; Go bounds `go` calls
with a semaphore channel. Every one takes work not yet started. With's
tasks start at the call, so the work-not-yet-started is the function.

**Prediction.** 80% (the #981 brief's shape after the measurement above
falsified its first option). Not C interop, ownership or safety; a std
signature nothing in-tree calls (its old call never compiled) is one
revert.

**Reopens if** lazy task sources are specified and a task-taking
bounded combinator earns its own name, or if results should stream
instead of collect.
