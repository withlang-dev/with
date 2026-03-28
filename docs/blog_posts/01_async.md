# Async in With: We Chose Fibers and We'd Do It Again

Every systems language eventually has to answer the async question. How do you let a program wait for I/O without burning a thread? The answer shapes everything downstream — how your code reads, how your libraries compose, how much of the type system leaks into function signatures that have nothing to do with types.

We spent a long time on this. We looked hard at Rust's state machine model. We looked at Go's goroutines. We looked at Java's Project Loom, Erlang's processes, Zig's choices. And we landed on **stackful fibers with explicit `.await`** — a model that gives you the readability of goroutines, the explicitness of Rust's `.await`, and none of the type system machinery that makes Rust's async a second language inside a language.

This post is about why.

---

## The Problem We Were Solving

With is a systems language. No garbage collector, native compilation, compile-time memory safety. Our ownership model is simpler than Rust's — no lifetime annotations, no stored references in structs, all borrowing is local — but it's still an ownership model. We need an async story that works *with* that model, not one that bolts on a parallel universe of types and traits.

The requirements were:

1. **Suspension must be visible.** If a function can yield control, you should see it in the source. No Go-style implicit preemption where any function call might context-switch.
2. **No colored functions.** Calling an async function from a sync context should work. You shouldn't need to restructure your program because one function deep in the call stack wants to do I/O.
3. **No type-system infection.** Async shouldn't introduce new trait bounds, wrapper types, or lifetime complications into code that doesn't care about concurrency.
4. **References should work normally.** If you have a reference before an await point, it should still be valid after. The ownership model shouldn't change because you waited for a network response.

That last requirement is the one that really narrowed the field.

---

## What We Chose

`async fn` in With declares a function that may suspend. Calling it spawns a lightweight fiber — a real stack, managed by the runtime — and returns a `Task[T]` handle immediately. `.await` suspends the current fiber until the task completes.

```
async fn fetch_user(id: UserId) -> Result[User, ApiError]:
    let resp = http.get("/users/{id}").await
    let body = resp.read_body().await
    json.decode(body)?
```

That's it. No `Future` trait. No `Pin`. No `Unpin`. No `Poll`. No `Waker`. No `Context`. These concepts do not exist in With. A fiber has a stack. References live on the stack. The stack doesn't move. Everything stays valid.

`.await` is postfix, so it chains naturally:

```
let user = pool.acquire().await?.query("SELECT ...").await?
```

And because `.await` just means "suspend this fiber," it works anywhere — including inside closures:

```
let results = urls.iter()
    |> map(url => fetch(url).await)
    |> filter(r => r.is_ok())
    |> collect[Vec]()
```

That last example is impossible in Rust without rewriting the whole thing to use `Stream` or `futures::join_all`. In With, standard synchronous iteration and standard async functions compose freely. This is probably the single biggest ergonomic advantage of the fiber model.

---

## Why Not State Machines?

Rust's async model is genuinely brilliant engineering. The compiler transforms `async fn` into a state machine struct that captures everything live across `.await` points. No runtime, no scheduler, no heap allocation in the common case. It's zero-cost in the C++ sense: you don't pay for what you don't use.

The cost is complexity. And it's not incidental complexity — it's fundamental to the model.

When you turn a function into a struct, local variables become struct fields. If any of those variables are references, you have a struct that contains references to itself. Self-referential structs are one of the hardest problems in Rust's ownership model. The solution is `Pin<&mut Self>` — a wrapper that promises the struct won't move. This works, but it cascades.

`Future::poll` takes `Pin<&mut Self>`. Any combinator that wraps a future needs to understand `Pin`. Any manual `Future` implementation needs to deal with `Pin`. Libraries that are generic over futures need `Unpin` bounds or `pin!()` macros. The trait signature for an async function in a trait — which Rust took years to stabilize — involves `Pin`, `Box`, lifetime bounds, and `Send` bounds that baffle even experienced Rust developers.

None of this is anyone's fault. It's the natural consequence of a design that is genuinely zero-cost. The information has to live somewhere, and in Rust it lives in the type system.

With makes a different trade-off: we pay a small runtime cost (fiber stacks) to keep that information out of the type system entirely.

### No Pin. References just work.

In With, a fiber has a real stack. A reference created before `.await` lives on that stack and stays valid after `.await`. The stack doesn't move. There is nothing to pin.

```
async fn process(data: &mut Vec[i32]):
    let first = &data[0]
    some_io().await              // fiber suspends; stack stays put
    println(first)               // reference still valid
    data.push(42)
```

In Rust, that example requires `Pin` because `first` would be a field in the generated `Future` struct pointing at another field. In With, it's just a pointer to a stack slot. The problem doesn't arise.

### No colored functions. Any function can call async functions.

In Rust, an `async fn` returns a `Future`, and you can only `.await` it inside another `async fn` or block. This means the moment one function in your call stack becomes async, everything above it must also become async — or you need to spin up a runtime and `block_on`.

In With, calling an `async fn` eagerly spawns a fiber and returns a `Task[T]`. You can call `fetch_user(id)` from any function — sync or async — and get a handle back. The only thing gated to the fiber runtime is `.await` itself, which suspends. The function isn't colored. The call just works.

This is a practical difference in library design. A With library doesn't need separate sync and async APIs. A function can call an async function, store the `Task`, and hand it off without ever touching `.await`.

### No Send bounds infecting return types.

In Rust, whether a `Future` is `Send` — safe to transfer across threads — depends on what it captures. If any local variable across an `.await` point is `!Send`, the whole future is `!Send`, and you'll learn about this via a compiler error twenty lines of generic bounds deep.

In With, `Task[T]` is `Send` when `T: Send` and the task doesn't capture references. There are no hidden captures to worry about because the fiber's state is its stack, not a compiler-generated struct that leaks internal details into the type system.

### One scheduler. No ecosystem fragmentation.

With has exactly one fiber scheduler. It's in the standard library. It's not a trait. It cannot be replaced.

This is an intentional rejection of Rust's pluggable executor model, where tokio, async-std, smol, and others all compete and fragment the ecosystem. Libraries have to choose a runtime, or abstract over all of them via traits, or just declare "we're a tokio library" and accept the lock-in.

In With, there's one scheduler. Libraries work with it. Done.

---

## The Honest Costs

We're not pretending fibers are free. They have real costs, and you should know what they are.

### Memory

Each fiber needs a stack. The default is growable starting at 8KB, up to 64KB. In practice, most fibers use far less than the maximum — growable stacks help a lot here. But the floor is still much higher than a Rust future, which is a small struct on the heap (often a few hundred bytes).

At 10K concurrent fibers, this doesn't matter. At 100K, you're potentially looking at 800MB of stack memory in the worst case, versus maybe 50MB for Rust-style futures. At 1M concurrent connections, fibers aren't viable without pooling strategies.

For most server workloads — the ones With targets — 10K-50K concurrent connections is the realistic range, and fibers handle that easily. But if you're building a proxy that holds 500K idle connections, read the last section of this post.

### FFI stack switching

C code doesn't know about With's segmented stacks. When a fiber calls into C via `c_import`, the runtime has to switch to a full OS-thread-sized stack at the FFI boundary. This costs roughly 10-50ns per switch — not free, but predictable. If you're calling C functions in a tight loop from a fiber, the `@[ffi_stack]` attribute lets you run the whole function on an OS stack to avoid per-call overhead.

### Cancellation latency

Fiber cancellation is cooperative — a cancelled fiber continues until its next `.await` point, then unwinds. If a fiber is in a long synchronous computation with no await points, it can't be cancelled until that computation finishes. Rust's future-dropping model has the same fundamental limitation (you can drop a future, but it only takes effect between polls), so this isn't unique to fibers — but it's worth knowing.

### No bare-metal async

The fiber runtime needs an OS to manage threads and memory. On `no_runtime` targets (embedded, bare-metal), `async fn` is a hard compile error. You get OS threads and interrupts on bare-metal, not fibers. This is an honest constraint, not a hidden one — if you see `async` in the source, a scheduler exists.

---

## Structured Concurrency

The async model includes structured concurrency as a first-class pattern. `async scope` guarantees all tracked tasks complete before the scope exits:

```
async scope s =>
    let user_task = s.track(fetch_user(id))
    let posts_task = s.track(fetch_posts(id))
    // both running concurrently
    let user = user_task.await?      // if this fails...
    let posts = posts_task.await?    // ...this was already cancelled
    Profile { user, posts }
```

If `user_task` fails and `?` triggers early return, the scope's destructor cancels `posts_task` and waits for it to unwind before the scope exits. No leaked tasks. No orphaned fibers.

`Task[T]` is `@[must_use]` — you can't accidentally drop a task without realizing it gets cancelled. If you want fire-and-forget, `spawn` makes the intent explicit:

```
spawn send_analytics("page_view")  // runs to completion, no handle
```

And `select await` handles racing with fair or biased selection:

```
loop:
    select await
        msg = inbox.recv() => process(msg)?
        _ = shutdown.recv() => break
        _ = timeout(idle_timeout) => send_heartbeat().await?
```

---

## When You Genuinely Need a Million Connections

Everything above is the 95% case. Fibers handle it beautifully. But some workloads genuinely need extreme connection density — load balancers, proxies, connection poolers, pub/sub brokers — where 100K+ connections sit idle most of the time and you can't afford a stack per connection.

For those cases, the standard library includes `std.async.sm` — a state machine module that ports Rust's `Future`/`Poll` model directly, minus `Pin`.

### Why no Pin?

Because With's core invariant — no stored references in structs — makes it unnecessary. In Rust, `Pin` exists because async state machine structs can be self-referential (a field referencing another field across an await point). With's state machine structs hold only owned values and handles, never references. They can always be moved safely. So `Pin` simply isn't needed.

### The API

```
use std.async.sm

enum Poll[T]:
    .Ready(T)
    .Pending

trait Future:
    type Output
    fn poll(mut self, cx: &Context) -> Poll[Self.Output]
```

You write state machines by hand — they're explicit enum types with a `poll` implementation:

```
type FetchState = enum:
    .Connecting(TcpStream)
    .Reading(TcpStream, Buffer)

impl Future for FetchState:
    type Output = Result[Response, IoError]
    fn poll(mut self, cx: &Context) -> Poll[Self.Output]:
        match self
            .Connecting(stream) =>
                if not stream.is_ready() then return .Pending
                self = .Reading(stream, Buffer.new())
                .Pending
            .Reading(stream, buf) =>
                match stream.try_read(buf)
                    .WouldBlock => .Pending
                    .Done => .Ready(Ok(parse(buf)))
                    .Err(e) => .Ready(Err(e))
```

Verbose? Yes. That's intentional. These are power-user tools for a specific scaling problem. A little friction signals "you probably want fibers unless you've measured otherwise."

### Bridging into fiber-land

The `into_task` function wraps any `Future` as a fiber-visible `Task[T]`:

```
fn into_task[F: Future](f: F) -> Task[F.Output]
```

From the fiber side, it's invisible:

```
async fn handle_request(conn: Connection):
    let request = FetchState.start(conn) |> into_task |> .await
    process(request)
```

The caller doesn't know or care that the underlying work is a state machine instead of a fiber.

### Standalone reactor

For pure state-machine workloads — no fibers, no scheduler, maximum density:

```
let reactor = SmReactor.new()
for conn in listener:
    reactor.register(FetchState.start(conn))
reactor.run()  // event loop, polls state machines directly
```

100K connections. No fiber stacks. Just a reactor polling tiny state machine structs. This is the same architecture as a tokio application, just without the compiler sugar.

### The trade-offs of state machines

You lose everything fibers give you. References don't survive suspend points — the state machine is a struct, and With structs can't hold references. `.await` inside closures and iterators doesn't work. The code is more verbose and harder to read. You're writing explicit state transition logic instead of sequential code.

But you gain extreme memory efficiency for connection-heavy workloads. A state machine struct might be 200 bytes. A fiber stack starts at 8KB. At 500K connections, that's the difference between 100MB and 4GB.

---

## The Full Picture

| Need | Tool |
|------|------|
| Most async code | `async fn` + `.await` (fibers) |
| Structured concurrency | `async scope` |
| Fire-and-forget | `spawn` |
| Racing tasks | `select await` |
| Joining tasks | `(task_a, task_b).await` |
| CPU-bound parallelism | `scope` (OS threads) |
| 100K+ idle connections | `std.async.sm` (state machines) |
| Bare-metal | OS threads, no async |

The vast majority of With code will never import `std.async.sm`. Fibers are the default, the ergonomic path, the thing the language is designed around. State machines are there for the people who need them — blessed, in the stdlib, interoperable with fibers, but deliberately not the easy road.

We think this is the right layering. Make the common case delightful. Make the power-user case possible. Don't let the power-user case complicate the common case.

That's the With way.