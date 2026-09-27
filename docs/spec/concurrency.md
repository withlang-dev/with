# 14. Concurrency

### 14.1 Design Principles

Three hard constraints govern the concurrency model:

1. **Suspension must be visible.** A systems programmer must see where
   a function can yield. Hidden suspension violates "predictable from
   source." This rules out Go-style implicit yielding.

   **Controlled exception:** Explicit cancellation or cleanup of an
   ephemeral `Task` may yield the current fiber (§14.7) to ensure
   memory safety. This is the only implicit suspension point in the
   language. The compiler does not silently detach ephemeral tasks:
   a task expression in statement position may detach only when the
   detach-safety check proves the task can outlive the current scope.
   If that proof fails, the statement is a compile error and the task
   must be awaited, cancelled, returned, or tracked before scope exit.
   Ephemeral Tasks cannot be created on OS threads or in FFI
   callbacks, because these contexts cannot suspend.

2. **No colored functions.** A function's callability must not depend on
   whether the caller is "async." This rules out Rust-style async.

3. **No type-system infection.** Concurrency must not introduce new
   trait bounds, wrapper types, or lifetime complications into code
   that doesn't need them.

The solution: `async`/`await` keywords that compile to **lightweight
thread (fiber) operations**, not state machine transformations.

### 14.2 What `async`/`.await` Mean in With

`async fn` declares a function that may suspend. Calling it spawns a
lightweight thread and returns a `Task[T]` handle immediately. `.await`
suspends the current fiber until a task completes.

```
async fn fetch_user(id: UserId) -> Result[User, ApiError]:
    let resp = http.get("/users/{id}").await
    let body = resp.read_body().await
    json.decode(body)?
```

`.await` is postfix, chaining naturally with `?` and `|>`:

```
// Postfix .await chains cleanly with ? and method calls
let user = pool.acquire().await?.query("SELECT ...").await?

// Compare with prefix await (not used in With):
// let user = await (await pool.acquire())?.query("SELECT ...")?
```

Each fiber has a **real stack**. References across `.await` points work
normally — they live on the stack, not in a compiler-generated struct.
No Pin, no Unpin, no Future, no Poll. These concepts do not exist in
With.

### 14.3 Formal Invariants

The following are **hard guarantees** that may never be violated:

**INVARIANT 1: No async function type exists.**
A function containing `await` does not change its type signature.
There is no `async fn` type distinct from `fn`. There is no trait
bound, wrapper type, or lifetime complication introduced by using
`.await`. Calling an `async fn` from a non-async `fn` is permitted —
the call spawns a fiber and returns a `Task[T]`, which the caller
may store, pass, or later `.await`.

**What "no colored functions" means here:** In Rust, an `async fn`
cannot be called from a non-async context without an executor and
explicit block-on machinery. In With, any function can call any
`async fn` — the call returns a `Task[T]` and execution continues.
The function is not "infected" by the call.

**What it does not mean:** `await` itself requires a fiber runtime.
Using `.await` in a `no_runtime` build is a compile error (Invariant
4). This is narrower than Rust's coloring: the restriction is on
*suspending*, not on *calling* async functions. A function that calls
`fetch_user(id)` but never awaits the result works in any build.
Only current-fiber suspension operations are gated; plain async calls
that only create a `Task[T]` are not.

**INVARIANT 2: No Future trait exists.**
`Task[T]` is an opaque handle. It has no `poll` method, no `Waker`,
no `Pin<&mut Self>`. It is not a trait. It cannot be implemented.

**INVARIANT 3: No pluggable executors.**
There is exactly one fiber scheduler. It is part of the standard
library. It is not a trait. It cannot be replaced. This prevents
ecosystem fragmentation.

**INVARIANT 4: `async` requires the fiber runtime.**
On `no_runtime` targets (embedded, bare-metal), `async fn` is a
**compile error**. This is not a fallback — it is a hard gate. If
you see `async` in the source, a fiber scheduler exists. If no
scheduler exists, `async` does not compile. The cost model is
always honest.

**INVARIANT 5: Suspension is trackable.**
With does not choose syntactic suspension visibility. It chooses
compiler suspension visibility. The compiler statically computes a
**`may_suspend`** property for every function and for callable type
information. Suspension need not be written at every call site, but it
must always be known to the compiler and surfaced in diagnostics when
it matters.

`may_suspend` is a **current-fiber** property, and fiber creation is
the firewall. A function is `may_suspend` if it directly performs a
primitive current-fiber suspension, or if it makes a same-fiber call
through a callable whose type is `may_suspend`. Calling an `async fn`
does not by itself make the caller `may_suspend`: it creates or starts
a separate fiber and returns a `Task[T]`. The caller suspends only if
it awaits, joins, performs async-scope cleanup, or otherwise invokes a
current-fiber suspension operation.

The primitive current-fiber suspension set is closed and deterministic:

- `.await`;
- collection / select await;
- explicit yield primitives;
- async-scope await-all and other structured-concurrency joins;
- implicit cleanup await at scope exit for a live ephemeral task;
- fiber-aware runtime operations that yield the current fiber when they
  cannot complete immediately: lock acquire when unavailable, channel
  send when full, channel receive when empty, timer/sleep until its
  deadline, and socket/file read or write when not ready.

Fiber-aware I/O and synchronization must choose one model explicitly:
either the operation is a direct current-fiber suspension primitive and
therefore participates in `may_suspend`, or it returns a `Task` and
suspends only when that task is awaited. The specification must not
leave that boundary ambiguous.

`may_suspend` is part of callable type information for function
pointers, closures, trait and `dyn` callables, callbacks, and every
other indirect-call surface. This does not reintroduce call-site
coloring: ordinary calls remain unannotated, and the typing burden
appears only when a function becomes a value.

Specific safety contexts enforce constraints based on current-fiber
suspension:

1. **`@[no_await_guard]` enforcement:** Making a same-fiber
   `may_suspend` call while a `@[no_await_guard]` guard is live is a
   compile error — even if the `.await` or yield primitive is buried
   three calls deep.
2. **FFI callback safety:** Functions passed as `extern "C"`
   callbacks must not be `may_suspend` (see §14.19).
3. **`no_suspend` blocks:** Expert code may assert that a region
   contains no operation that yields to the scheduler. The compiler
   rejects direct `.await`, collection/select await, same-fiber
   `may_suspend` calls, structured-concurrency joins, implicit cleanup
   awaits, and direct fiber-aware runtime operations in that region.

Programmers do not declare or annotate `may_suspend`. The compiler
computes it internally; it may appear in diagnostics when a safety
violation occurs. There are no separate `async` and `sync` function
types and no trait split. Callable values still carry whether invoking
them may suspend the current fiber, because indirect calls must be
checkable.

```
fn helper:
    some_io().await        // makes helper() may_suspend

with lock.write() as data:
    helper()               // ERROR E0701: same-fiber may_suspend call
                           // while @[no_await_guard] WriteGuard is live
    data.x = 1             // OK: no suspension
```

#### 14.3.1 `no_suspend` Blocks

`no_suspend` is an expert assertion for code that must not yield to
the fiber scheduler:

```
no_suspend:
    update_intrusive_state()
    poll_fast_path()

let inline_value = no_suspend: compute_without_waiting()

let value = no_suspend {
    compute_without_waiting()
}
```

The body is otherwise an ordinary expression block: it has the type of
its tail expression and participates in inference normally. Creating an
async task handle is allowed because calling an `async fn` returns a
`Task[T]` immediately; actually awaiting that task inside the block is
not allowed.

The compiler rejects any scheduler-yielding operation inside the block,
including:

- direct `.await`, collection await, or `select await`
- same-fiber calls through `may_suspend` callables
- async-scope await-all and other structured-concurrency joins
- implicit cleanup await for an ephemeral `Task`
- direct fiber-aware runtime operations that may yield the current
  fiber

This check exists because suspending inside such a region can deadlock
or expose partially-updated state to other fibers. It is independent of
whether the compiler implements fibers with real stacks or state
machines.

### 14.4 `async fn` Semantics

```
async fn fetch(url: str) -> Result[String, IoError]: ...
```

Calling `fetch(url)` does the following:

1. Allocates a lightweight thread (fiber) with its own stack.
2. Begins executing the function body on that fiber.
3. Returns a `Task[Result[String, IoError]]` handle immediately
   to the caller.

The fiber runs concurrently. It suspends at compiler-known
current-fiber suspension points and is resumed by the scheduler when
the awaited operation or runtime wait completes.

### 14.5 `.await` Semantics

```
let result = task.await
```

`.await` does the following:

1. If the task is already complete, returns the result immediately.
2. If the task is still running, **suspends the current fiber** and
   yields to the scheduler. When the task completes, the current
   fiber is resumed.
3. If called from an OS thread with no fiber runtime, this is a
   **compile error** (see Invariant 4).

`.await` is the primary explicit suspension operator for observing a
single `Task[T]` result. Tuple `.await`, collection await combinators,
and `select await` are also result-observing suspension forms for
multiple tasks.

`.await` is not the only operation that can suspend the current fiber.
Any operation classified by the compiler as `may_suspend` may yield the
current fiber. Suspension is always known to the compiler and surfaced
in diagnostics, but it is not necessarily spelled at every call site.

`.await` is postfix — it appears after the expression it operates
on. This allows natural chaining:

```
// Chain with ? for error propagation
let body = http.get(url).await?.read_body().await?

// Chain with |> for pipelines
let users = fetch_all(ids).await?
    |> filter(u => u.active)
    |> collect()
```

### 14.6 `async:` Blocks

An `async:` block creates and immediately starts a fiber inline,
returning a `Task[T]`:

```
let task = async:
    let a = fetch("http://a.com").await?
    let b = fetch("http://b.com").await?
    Ok(a + b)
// task: Task[Result[String, IoError]]
```

**Semantics:** `async: body` allocates a fiber, begins execution
of `body`, and returns a `Task[T]` where `T` is the type of `body`.
The fiber runs concurrently with the caller.

This is the async analog of a regular block expression and is
essential for inline structured concurrency:

```
async scope s =>
    s.track(async:
        for i in 0..5:
            sleep(50.millis()).await
            tx.send("msg-{i}").await
    )
    s.track(async:
        for msg in rx:
            print(msg)
    )
```

Without `async:` blocks, users would need to define a separate
`async fn` for every inline concurrent task — significant
boilerplate when the logic is small and context-specific.

**Capture rules:** `async:` blocks follow the same capture rules
as closures. They may capture references (making the resulting
`Task` ephemeral) or owned values (storable `Task`). See §14.22.

### 14.7 `Task[T]`

```
type Task[T]       // opaque handle to a running fiber
```

| Method | Signature | Description |
|--------|-----------|-------------|
| `.await` | postfix keyword | Suspend fiber until complete |
| `cancel` | `(Task[T]) -> Unit` | Cooperative cancellation |
| `is_done` | `(&Task[T]) -> bool` | Check without blocking |
| `was_cancelled` | `(&Task[T]) -> bool` | True if the task was cancelled before completing normally; never suspends |

`Task[T]` has one type spelling. Storability and sendability are
properties of the task value and binding, inferred from what the task
captures and returns:

- **Ephemeral vs non-ephemeral** is the lifetime gate. A task is
  ephemeral if its captured environment or result contains references,
  allocator-borrowed values, scope-bound resources, or any other
  ephemeral value.
- **Storable** means the task may be placed in long-lived data. A task
  is storable iff it is non-ephemeral. Storage alone does not require
  `Send`; a non-`Send` task may be stored in same-thread data, and that
  container is then itself non-`Send`.
- **Sendable** means the task may cross a thread boundary. A task is
  sendable iff it is non-ephemeral, `T: Send`, and its captured
  environment is `Send`.

A `Task[T]` that captures references is **ephemeral** (see §14.22).
Ephemeral tasks cannot be stored, returned, or sent to other threads.
They must be awaited or tracked in a scope before the borrowed data
goes out of scope.

**Task disposition:** A `Task` handle represents running work. The
compiler uses syntactic position as the programmer's intent.

A `Task` in **statement position** is intentional fire-and-forget
detachment:

```
send_analytics("page_view")  // detach if both checks below pass
```

This means: start the work, do not await it, and discard interest in
its result or failure. It is allowed only when two independent checks
both pass:

1. **must-observe:** the API author has not marked the task's
   completion or failure as requiring observation.
2. **detach-safety:** the compiler proves the task may safely outlive
   the current scope. It must not carry borrowed stack data, ephemeral
   captures, allocator-borrowed or scope-bound resources, or structured
   concurrency cleanup obligations out of the scope that owns them.

Author intent never substitutes for the lifetime proof, and the
lifetime proof never overrides author intent. Both gates must clear.

When statement-position detachment fails, the compiler emits a hard
error naming the failed check:

```
error[E0801]: task result must be observed
  --> src/service.w:42:9
   |
42 |     send_invoice(invoice)
   |     ^^^^^^^^^^^^^^^^^^^^^ this task is marked must-observe
   |
   = help: await, cancel, return, store, or otherwise handle the task

error[E0802]: task cannot be detached safely
  --> src/service.w:51:9
   |
51 |     borrow_until_done(&buffer)
   |     ^^^^^^^^^^^^^^^^^^^^^^^^^^ task captures data owned by this scope
   |
   = help: await, cancel, return, or restructure so the task no longer carries scope-bound state out of scope
```

A task **bound to a name** declares intent to observe:

```
let task = send_invoice(invoice)
task.await?
```

An unused bound task handle is a compile error. The handle must be
awaited, cancelled, returned, stored when non-ephemeral, tracked in an
`async scope`, or otherwise given a valid disposition before it is
lost.

**`let _ = task` is not the fire-and-forget spelling.** Statement
position already expresses detachment. The compiler rejects
`let _ = <Task expression>` for task values; use a bare statement for
permitted fire-and-forget work, or bind the task and call `cancel`
when cancellation is the intended effect.

See §20b.2.

**Cancellation semantics:**

Cancellation is **cooperative, not preemptive** for non-ephemeral
tasks. When `cancel()` is called or a non-ephemeral `Task` is dropped:

1. A cancellation flag is set on the fiber.
2. The fiber continues executing until it reaches its next `await`
   point.
3. At that `await` point, instead of suspending, the fiber begins
   unwinding.
4. **Destructors are guaranteed to run** during unwinding, in reverse
   declaration order, just as with normal scope exit.
5. Cancellation **propagates to child tasks**: if a fiber is cancelled,
   any tasks it spawned via `async scope` are also cancelled.
6. **Awaiting a cancelled task:** Awaiting a cancelled task triggers
   **cancellation unwinding** — similar to a panic, but structured
   and absorbed at `async scope` boundaries. Awaiting a cancelled
   task never produces an `Err` value of the task's error type:
   cancellation is a control transfer, not an error value.
   Destructors and `defer` blocks run during unwinding as usual.

   ```
   async scope s =>
       let t1 = s.track(fetch_user(id))
       let t2 = s.track(fetch_posts(id))
       let user = t1.await?           // if this fails...
       // t2 is cancelled, unwinds, destructors run
       let posts = t2.await?          // cancellation unwinds through
                                      // this await to the scope
   ```

   `async scope` absorbs cancellation unwinding from its child
   tasks. No error types change. No `From` impls are needed.
   `IoError`, `DbError`, `ApiError` — they all work unchanged. There
   is no `TaskCancelled` error type and no `.is_cancelled()` method
   on errors; user error types never represent cancellation.

   To distinguish cancellation from completion or failure, observe
   the **task handle**, not the error channel:

   ```
   cancel(task)
   if task.was_cancelled():
       log("task was cancelled before producing a result")
   else:
       let value = task.await
       use(value)
   ```

   `was_cancelled(&Task[T]) -> bool` reports whether the task was
   cancelled before completing normally. It never suspends.

**Cancellation of ephemeral tasks:** If a `Task` is ephemeral
(captures references), cancelling it or unwinding the scope that owns
it must ensure the fiber has stopped before the caller proceeds. This
is mandatory for memory safety: the fiber holds references to the
caller's stack.

**The runtime handles this without blocking the OS thread:**

1. The cancellation flag is set on the child fiber.
2. If the child fiber is idle (suspended at an `.await`), it is
   immediately unwound. The parent continues.
3. If the child fiber is scheduled on the **same** OS thread (i.e.,
   it is in the thread's run queue, not currently executing — the
   parent is currently running), the runtime immediately switches
   to the child fiber and runs it until its next `.await` point,
   then unwinds it and resumes the parent. No scheduler involvement.
4. If the child fiber is actively running on a **different** OS
   thread, the parent fiber **yields** (not blocks the OS thread)
   and the scheduler prioritizes the child for cancellation. When
   the child reaches `.await` and unwinds, the parent is resumed.

This avoids the deadlock scenario where N OS threads all block
waiting for fibers that can never be scheduled. The key insight is
that ephemeral task cleanup happens inside fibers (which can yield),
not inside raw OS thread code.

```
var data = [1, 2, 3]
let task = process(data)
cancel(task)                // runtime ensures fiber stops before
                            // proceeding (may yield)
// data is safe — fiber is guaranteed stopped
```

Non-ephemeral tasks (capturing only owned values) use cooperative
cancellation — the fiber continues until it hits `.await` on its
own schedule, with no urgency.

A fiber that is blocked in a long synchronous computation (no `await`
points) cannot be cancelled until it reaches an `await`. For
ephemeral tasks, this means the parent fiber waits (yielding to the
scheduler) for the duration of that computation. If both fibers are
on the same OS thread, the computation runs inline. This is the
trade-off of memory safety without `Pin`.

**Restriction:** Ephemeral tasks can only be created inside fibers
(async contexts). Creating an ephemeral task on a bare OS thread
(e.g., inside `thread.spawn_os`) or in an FFI callback is a
**compile error**, because these contexts cannot yield to the
scheduler and ephemeral cleanup could need to yield. Non-ephemeral
tasks (capturing only owned values) can be created anywhere.

### 14.8 Parallel Execution

```
async fn fetch_profile(id: UserId) -> Result[Profile, ApiError]:
    let user_task = fetch_user(id)       // fiber starts
    let posts_task = fetch_posts(id)     // fiber starts
    // both running concurrently
    let user = user_task.await?
    let posts = posts_task.await?
    Ok(Profile { user, posts })
```

### 14.9 Structured Concurrency

`async scope` creates a scope in which tasks are tracked with the
guarantee that **all tasks complete before the scope exits**.

**Formal semantics:**

```
async scope s =>
    body
```

As with other block-introducing constructs, the body may use an
inline expression, an indented colon block, or a braced block:

```
async scope s => fetch().await
async scope s =>:
    fetch().await
async scope s { fetch().await }
```

desugars to:

```
runtime::structured_scope(s => { body })
```

The scope object `s` provides:

| Method | Signature | Description |
|--------|-----------|-------------|
| `track` | `(Task[T]) -> ScopedTask[T]` | Register an existing task with this scope |

**Why `track`, not `spawn`:** In With, calling an `async fn` eagerly
allocates a fiber and returns a `Task[T]` (§14.4). If a scope took
a closure like `s.spawn(() => async_fn())`, the closure would run on
one fiber and `async_fn()` would spawn a second — creating a
detached task that escapes structured concurrency. Instead,
`s.track()` accepts the `Task[T]` directly:

```
async scope s =>
    // fetch_user(id) eagerly spawns a fiber, returns Task
    // s.track() registers it with the scope
    let task = s.track(fetch_user(id))
    task.await
```

**`ScopedTask[T]`:** The value returned by `s.track()`. It behaves
like `Task[T]` (supports `.await`, `cancel`, `is_done`) but is
**exempt from `@[must_use]`**. The scope guarantees cleanup: when
the scope exits (normally or via early `?` return), all tracked
tasks that haven't been awaited are cancelled and joined.
`ScopedTask[T]` is ephemeral: it may be used inside the scope, but
the scope body may not return it or store it in non-ephemeral data.

This solves the `?` interaction problem:

```
async scope s =>
    let posts_task = s.track(self.repo.count_posts(id))
    let followers_task = s.track(self.repo.count_followers(id))

    // If this fails and returns early via ?,
    // followers_task is cancelled by the scope's destructor.
    // No @[must_use] error — ScopedTask is scope-managed.
    let posts = posts_task.await?
    let followers = followers_task.await?
    (posts, followers)
```

**Guarantees:**

1. All tasks tracked via `s.track` will complete (or be cancelled)
   before `async scope` returns.
2. If any tracked task panics, all sibling tasks are cancelled and
   the panic propagates to the scope.
3. The scope is an expression — it returns the value of `body`.
4. `s` cannot escape the scope. It is ephemeral.
5. The scope result cannot be ephemeral. Await or copy the value
   before it leaves the scope.

```
async fn handle_batch(ids: Vec[UserId]) -> Vec[Result[User, ApiError]]:
    async scope s =>
        let tasks = ids.iter()
            |> map(id => s.track(fetch_user(id)))
            |> collect[Vec]()
        tasks |> map(t => t.await) |> collect()
    // all tracked tasks guaranteed complete here
```

For CPU-bound parallelism on OS threads (no fiber runtime required):

```
scope s =>
    s.spawn(() => compute_chunk_a())
    s.spawn(() => compute_chunk_b())
// both complete here
```

The non-async `scope` uses `s.spawn(() => closure)` because OS-thread
work items are sync closures — no eager fiber spawning occurs.
`s.spawn(worker)` returns a `ScopedJoinHandle`, which supports
`.join() -> i32` and is joined automatically at scope exit if it has
not already been joined. `ScopedJoinHandle` is ephemeral: it may not
leave the `scope` result or be stored in non-ephemeral data. `scope`
supports the same inline, colon, and braced body forms and is
available in `no_runtime` builds.

### 14.10 Select Await

`select await` races multiple async expressions and executes the
branch of the first to complete. Remaining expressions are cancelled.

```
select await
    msg = rx_fast.recv() => print(f"fast: {msg}")
    msg = rx_slow.recv() => print(f"slow: {msg}")
    _ = timeout(1.secs()) => print("timeout")
```

Each branch has the form `pattern = async_expr => body`. The runtime
starts all expressions concurrently, the first to resolve fires its
branch, and all siblings are cancelled (structured cancellation).

**Type safety:** Each branch handles its own return type
independently — no shared enum wrapper needed. This scales to any
number of branches without `First`/`Second`/`Third` boilerplate.

**Composing with `?` and loops:**

```
// Select in a loop (event loop pattern)
loop:
    select await
        msg = inbox.recv() =>
            process(msg)?
        _ = shutdown.recv() =>
            break
        _ = timeout(idle_timeout) =>
            send_heartbeat().await?

// Select with error propagation
select await
    data = stream.next() => process(data?)?
    _ = cancel.cancelled() => return Err(.Cancelled)
```

**Fair selection (default):** If multiple expressions complete
simultaneously, the runtime selects a **ready branch at random**
(pseudo-random, not cryptographic). This prevents starvation: a
high-throughput data channel cannot indefinitely starve a shutdown
signal or heartbeat timer.

```
loop:
    select await
        data = fast_stream.recv() => handle(data)
        _ = shutdown.recv() => break    // will eventually fire
```

**Biased selection:** For cases where deterministic priority is
needed, use `select await biased`. This selects the first textual
branch that is ready (top-to-bottom priority):

```
select await biased
    urgent = priority_rx.recv() => handle_urgent(urgent)
    normal = normal_rx.recv() => handle_normal(normal)
    _ = timeout(1.secs()) => send_heartbeat().await
```

Use `biased` when you need guaranteed priority ordering and
understand the starvation risk.

**Handling `Option`/`Result` in branches:** Use `let ... else`
inside the branch body to destructure the completed value. This
reuses existing syntax and keeps the grammar simple:

```
loop:
    select await
        opt_msg = rx.recv() =>
            let Some(msg) = opt_msg else break
            process(msg)
        result = listener.accept() =>
            let Ok(conn) = result else continue
            handle(conn)
        _ = timeout(idle_timeout) =>
            send_heartbeat().await
```

**Exhaustiveness:** `select await` does not require a default branch.
At least one branch must be present. Branch patterns are irrefutable
bindings; refutable handling belongs in the branch body via
`let ... else` (above).

### 14.11 Concurrent Await

When `.await` is applied to a tuple of tasks, all elements execute
concurrently and the result is a tuple of their results.

```
let (user, posts) = (fetch_user(id), fetch_posts(id)).await
let (user, posts) = (fetch_user(id), fetch_posts(id)).await?
let (a, b, c) = (fetch_a(), fetch_b(), fetch_c()).await
```

Given `(Task[A], Task[B], ..., Task[N])`, tuple `.await` returns
`(A, B, ..., N)`.

Calling an `async fn` eagerly spawns a fiber (§14.4), so tuple
`.await` is a join operation over already-running tasks.

Error handling with `?` composes in tuple order:

`(Task[Result[A, E]], Task[Result[B, E]]).await?` has type `(A, B)`.

If `?` triggers early return from an `async scope`, tracked siblings
are cancelled by normal scope unwinding rules. Outside `async scope`,
normal `Task` drop semantics apply (§14.7).

```
async scope s =>
    let (user, posts) = (
        s.track(fetch_user(id)),
        s.track(fetch_posts(id)),
    ).await
    (user?, posts?)
```

Tuple `.await` supports tuple sizes 2..12. For dynamic or larger
sets, use collection combinators.

Desugaring (2-tuple):

```
(task_a, task_b).await
// desugars to:
{
    let __ta = task_a
    let __tb = task_b
    (__ta.await, __tb.await)
}
```

Runtime implementations may use a multi-wait join internally; observable
semantics are completion of all tasks with results in tuple order.

| Need | Construct |
|------|-----------|
| Await 2–12 heterogeneous tasks | `(task_a, task_b).await` |
| Await N homogeneous tasks | `tasks |> await_all` |
| First task to complete | `tasks |> await_first` |
| First successful task | `tasks |> await_any` |
| All results including errors | `tasks |> await_settled` |
| First of N with pattern dispatch | `select await` (§14.10) |
| Dynamic spawn + cancellation scope | `async scope` (§14.9) |
| Fire-and-forget | task expression statement (§14.7) |

#### 14.11.1 Collection Await (Standard Library)

Collection await is a standard-library surface, not special syntax:

```
let users = ids |> map(fetch_user) |> await_all?
let fastest = tasks |> await_first
let winner = tasks |> await_any?
let results = tasks |> await_settled
```

Collection combinators follow deterministic semantics:

- `await_all(Task[T]) -> Vec[T]` waits for all tasks and returns results in input order.
- `await_all(Task[Result[T, E]]) -> Result[Vec[T], E]` is fail-fast: on first `Err`, it cancels and joins remaining tasks, then returns that `Err`.
- `await_first(Task[T]) -> T` returns the first completed result, then cancels and joins losers before returning.
- `await_any(Task[Result[T, E]]) -> Result[T, Vec[E]]` returns first `Ok(T)` (then cancels + joins losers); if all fail, returns `Err(Vec[E])` in input order.
- `await_settled(Task[Result[T, E]]) -> Vec[Result[T, E]]` never cancels, waits for all, and returns in input order.

**Latency note:** "cancels and joins" means the combinator does not
return until every losing task has actually stopped. Cancellation is
cooperative (§14.7): a loser inside a long synchronous computation
delays the combinator's return until that loser reaches its next
suspension point.

Empty-input behavior:

- `await_first([])` panics with stable message:
  `"await_first: empty input"`.
- `await_any([])` returns `Err(Vec.new())`.
- For non-empty input, `await_any` all-fail result is guaranteed
  non-empty (`Err(errors)` where `errors.len() > 0`).

Ordering guarantee for `await_any` all-fail:

- Errors are aggregated in **input order**, not completion order.

Cancellation/drop contract for collection combinators:

- If a combinator returns early (winner found or fail-fast trigger),
  it cancels all remaining owned tasks and joins them before return.
- If the combinator itself is cancelled/dropped mid-flight, it
  cancels remaining owned tasks and joins them before unwinding.

See `lib/std/async.w` and `lib/std/async/` docs for API details.

*§14.12 Why Fibers, Not State Machines? moved to `docs/spec/implementation/why-fibers.md`.*

### 14.13 Interaction with Ownership

Because fibers have real stacks, references across `await` are safe:

```
async fn process(mut data: Vec[i32]) -> Vec[i32]:
    let first = &data[0]
    some_io().await              // fiber suspends; reference still valid
    print(first)               // safe to use
    data.push(42)
    data
```

In Rust, this requires `Pin<&mut Self>` because the Future is a
struct and references into it invalidate on move. Here, the fiber
stack doesn't move.

**`.await` works inside standard higher-order functions.** Because
fibers have real stacks, `.await` is valid anywhere — including
inside closures passed to `map`, `filter`, `fold`, and `for_each`.
No specialized `AsyncIterator` or `Stream` traits are needed:

```
// This is valid With code — impossible in Rust without Stream
let results = urls.iter()
    |> map(url => fetch(url).await)
    |> filter(r => r.is_ok())
    |> collect[Vec]()

// .await inside fold
let total = ids.iter()
    |> fold(0, (sum, id) => sum + get_count(id).await)
```

This is one of the most significant ergonomic advantages of the
fiber model. In Rust, any use of `.await` inside an iterator
closure requires rewriting to use `Stream`, `futures::join_all`,
or manual loops. In With, standard synchronous iteration and
standard async functions compose freely.

**Implementation note:** The language guarantees **semantic stack
preservation** — safe references remain valid across `await` points.
The conforming baseline uses fixed, non-relocating pooled stacks
(§14.19), where preservation is trivial. An implementation may
relocate or segment physical stacks only if the compiler ensures safe
references are updated or indirected transparently. Raw pointers (`*const T`, `*mut T`) obtained via
`unsafe` are **not** updated — they are bare addresses. This is why
§19.3 forbids raw pointers to stack locals across `await`. Safe code
is never affected.

### 14.14 OS Threads (Always Available)

OS threads exist independently of the fiber runtime and are available
in all builds, including `no_runtime`:

```
thread.spawn_os(closure) -> JoinHandle[T]
JoinHandle.join() -> T
```

For structured CPU-bound parallelism:

```
scope s =>
    s.spawn(() => compute_chunk_a())
    s.spawn(() => compute_chunk_b())
// both complete here
```

*§14.15 Channels moved to `docs/spec/stdlib/channels.md`.*

*§14.16 Send, Sync, and ScopedSend moved to `docs/spec/stdlib/send-sync-scopedsend.md`.*

*§14.17 Synchronization Primitives moved to `docs/spec/stdlib/synchronization-primitives.md`.*

#### 14.17.1 Atomic[T]

`Atomic[T]` provides lock-free atomic operations on integer and
pointer types. `T` must be an integer type (`i32`, `i64`, `u32`,
`u64`, etc.) or a pointer type.

```
use std.collections

var counter: Atomic[i32] = Atomic { val: 0 }

counter.store(42, .Release)
let val = counter.load(.Acquire)

let old = counter.fetch_add(1, .SeqCst)
```

**Memory orderings:**

```
.Relaxed       // no ordering guarantees (fastest)
.Acquire       // reads after this see writes before a paired release
.Release       // writes before this are visible after a paired acquire
.AcqRel        // both acquire and release
.SeqCst        // total order across all threads (strongest, default)
```

**Operations:**

| Method | Signature | Description |
|--------|-----------|-------------|
| `Atomic.new(val)` | `fn(T) -> Atomic[T]` | Create with initial value |
| `.load(order)` | `fn(Order) -> T` | Atomic read |
| `.store(val, order)` | `fn(T, Order) -> void` | Atomic write |
| `.swap(val, order)` | `fn(T, Order) -> T` | Exchange, return old |
| `.fetch_add(val, order)` | `fn(T, Order) -> T` | Add, return old |
| `.fetch_sub(val, order)` | `fn(T, Order) -> T` | Subtract, return old |
| `.fetch_and(val, order)` | `fn(T, Order) -> T` | Bitwise AND, return old |
| `.fetch_or(val, order)` | `fn(T, Order) -> T` | Bitwise OR, return old |
| `.fetch_xor(val, order)` | `fn(T, Order) -> T` | Bitwise XOR, return old |
| `.fetch_min(val, order)` | `fn(T, Order) -> T` | Min, return old |
| `.fetch_max(val, order)` | `fn(T, Order) -> T` | Max, return old |
| `.compare_exchange(expected, desired, success, failure)` | `fn(T, T, Order, Order) -> Result[T, T]` | CAS, strong |
| `.compare_exchange_weak(expected, desired, success, failure)` | `fn(T, T, Order, Order) -> Result[T, T]` | CAS, weak |

`compare_exchange` returns `Ok(old_value)` on success or
`Err(actual_value)` on failure.

**Atomic fences:**

```
use std.sync.fence

fence(.Acquire)
fence(.Release)
fence(.SeqCst)
```

**Ordering constraints (compile-time validated):**

- `.store` cannot use `.Acquire` or `.AcqRel`
- `.load` cannot use `.Release` or `.AcqRel`
- `compare_exchange` failure ordering cannot be stronger than
  success ordering, and cannot be `.Release` or `.AcqRel`

*§14.18 The Fiber Runtime moved to `docs/spec/implementation/fiber-runtime.md`.*

*§14.19 Fiber Stack Management moved to `docs/spec/implementation/fiber-stack-management.md`.*

### 14.20 Generators vs. Async: A Clarification

Generators (`gen fn`) and async functions (`async fn`) look
syntactically similar but compile to fundamentally different
mechanisms:

|  | `gen fn` | `async fn` |
|--|---------|-----------|
| **Mechanism** | Ordinary call: the generator calls the loop body at each `yield` | Fiber (runtime) |
| **Runtime required** | No (`pull()` needs fibers) | Yes |
| **Suspends** | Never by itself; a `.await` in its body suspends the consumer's fiber | At compiler-known current-fiber suspension points |
| **Driver** | The generator; `pull()` gives a caller-driven `Iter[T]` | Fiber scheduler |
| **Allocation** | None; the generator value holds its arguments | Heap stack per fiber |
| **Storable** | Yes, unless an argument is a view | Task handle; storable only when non-ephemeral |
| **Sendable** | When its arguments are `Send` | Only when non-ephemeral, `T: Send`, and captures are `Send` |
| **`no_runtime` builds** | Works (without `pull()`) | Compile error |

`gen fn` compiles entirely away — it is an ordinary function that
calls the consumer's loop body at each `yield` (§13.4). It has no
scheduler dependency and works in `no_runtime` builds.

`async fn` allocates a fiber with a real stack and requires the fiber
runtime. It can suspend at compiler-known current-fiber suspension
points and be driven by the scheduler.

If you want a lazy sequence that works everywhere, use `gen fn`. If
you want concurrent I/O, use `async fn`. They are complementary
tools, not alternatives.

*§14.21 Real-World Example moved to `docs/spec/guide/real-world-example.md`.*

### 14.22 Task Ephemerality and Send

A `Task[T]` may capture values from its spawning environment. The
ephemerality and `Send`-ability of the task depends on what it
captures:

**Rule:** A `Task[T]` is ephemeral if its spawned fiber environment
contains any ephemeral values (references, views, guards). A `Task[T]`
is `Send` only if all captured values are `Send` and the task is not
ephemeral.

```
// Owned-argument task: fully storable, Send
let task = fetch_user(id)              // id: UserId is owned
// task is Task[Result[User, DbError]], storable, Send

// Borrowing task: ephemeral — cannot be stored or sent
async fn process(data: &Vec[i32]) -> Unit: ...
let task = process(&my_vec)            // captures &my_vec
// task is ephemeral — it borrows my_vec
// Cannot store in a struct, cannot send to another thread
```

**How the compiler tracks this:** Ephemerality is a per-binding
property, not a per-type property. The type `Task[i32]` is the
same whether ephemeral or storable. The compiler determines
ephemerality at the creation site by analyzing the arguments: if
any argument is a reference or ephemeral value, the resulting Task
binding is marked ephemeral. This marking propagates through
assignments and function calls.

**Passing ephemeral values to functions:** Ephemeral values can be
passed to functions — by reference or by value — only when the
compiler can prove the value remains within its valid scope, or when
the callee's effect summary propagates the ephemerality/origin
information to its result. Ephemerality is part of With's safety
contract: if the compiler cannot prove that an ephemeral value's
origin outlives every use, the program is not safe With code.

Clear ephemeral escapes are compile errors. Ambiguous or unproven
ephemeral escapes are also compile errors, because ambiguity means the
compiler cannot prove safety. The user can resolve the error by
keeping the value within scope, returning it with propagated
ephemerality, converting or copying into owned data, or crossing an
explicit `unsafe` boundary.

```
fn process_task(t: Task[i32]):
    t.await                          // OK: consumes the task

fn store_globally(t: Task[i32]):
    GLOBAL_TASKS.push(t)            // ERROR: storing a value that
                                     // may be ephemeral at some call sites

var v = [1, 2, 3]
let task = process(&v)              // ephemeral task
process_task(task)                   // OK: compiler sees task is consumed
store_globally(task)                 // ERROR: compiler cannot prove the
                                     // ephemeral task stays in scope
```

Warnings are appropriate for weird-but-safe code, performance
guidance, style, or suspicious but semantically valid patterns. They
are not sufficient when accepting the program could produce a dangling
reference, cross-thread borrowed value, detached ephemeral task, or
erased origin.

**Ephemeral tasks CAN be returned from functions** — the caller's
binding inherits the ephemerality (Rule 8, §22.1). This is
essential: `async fn get_profile(self: &UserService)` returns a
`Task` that captures `&self`. The returned task is ephemeral at
the call site, preventing the caller from storing it or outliving the
referenced data:

```
let task = svc.get_profile(id)   // ephemeral: borrows &svc
task.await?                       // OK: used immediately
// task cannot be stored in a struct or global
```

**`async scope` is the ergonomic solution** for borrowing tasks:

```
async fn process_all(mut data: Vec[i32]) -> Vec[i32]:
    async scope s =>
        // These tasks borrow data — ephemeral
        let t1 = s.track(transform(&data[0..100]))
        let t2 = s.track(transform(&data[100..200]))
        t1.await
        t2.await
    // Scope guarantees both tasks complete here.
    // Borrows of data are released.
```

Because `async scope` guarantees all tracked tasks complete before
the scope exits, the compiler knows the borrows cannot outlive their
referents — no lifetime annotations needed.

**Summary:**

| Task captures | Ephemeral? | Storable? | `Send`? |
|---------------|-----------|-----------|---------|
| Only owned `Send` values | No | Yes | Yes (if `T: Send`) |
| Owned but non-`Send` values | No | Yes | No |
| References/views | Yes | No | No |
| `@[no_await_guard]` guards | N/A | N/A | Compile error (§7.9) |

This is the same rule as generator values (§13.4): a value that holds
an ephemeral is ephemeral. This
avoids reintroducing lifetime annotations while preserving safety.

---
