# State Machine Async — Specification & Implementation Notes

*`std.async.sm` — Opt-in high-density async without fiber stacks*

---

## 1. Overview

With's primary async model is fiber-based: `async fn`, `.await`, `spawn`, lightweight
stacks managed by the runtime. This covers the vast majority of async workloads with
excellent ergonomics.

For the narrow case where fiber stack overhead matters — 100K+ concurrent connections,
each doing simple request-response I/O — `std.async.sm` provides Rust-style
state-machine futures as a library, not a language feature. State machines are
heap-allocated enums with no stack. They are polled by a reactor or bridged into
fiber-land via `into_task`.

**The key insight:** With bans stored references in structs. Rust's `Pin<&mut Self>`
exists entirely to protect self-referential futures (local references captured across
`.await` points). With's futures can never be self-referential, so `Pin` doesn't exist.
The result is Rust's async performance model without Rust's async complexity model.

**Design principles:**

- Fibers are the default. State machines are the opt-in.
- No language changes. No new keywords. No function coloring.
- `into_task` bridges state machines into fiber-land transparently.
- No macro for generating state machines. Explicitness is a feature.
- The restriction (no references across suspend points) matches the use case
  (simple I/O handlers don't need them).

```
use std.async.sm

// Fibers: the default — ergonomic, references work everywhere
async fn handle_request(conn: Connection) -> Response:
    let req = conn.read_request().await
    let data = db.query(req.id).await
    Response.ok(data)

// State machines: the opt-in — zero stack overhead, explicit transitions
enum FetchState:
    Connecting(TcpStream)
    Reading(TcpStream, Buffer)

impl Future for FetchState:
    type Output = Result[Response, IoError]
    fn poll(mut self, cx: &Context) -> Poll[Self.Output]:
        match self
            .Connecting(stream) =>
                if not stream.poll_ready(cx): return .Pending
                self = .Reading(stream, Buffer.new())
                .Pending
            .Reading(stream, buf) =>
                match stream.poll_read(buf, cx)
                    .Pending => .Pending
                    .Ready(Ok(())) => .Ready(Ok(parse(buf)))
                    .Ready(Err(e)) => .Ready(Err(e))

// Bridge: state machine → Task, invisible to the caller
async fn handle_connection(conn: Connection):
    let response = into_task(FetchState.Connecting(conn)).await
    send(response)
```

---

## 2. Core Types

### 2.1 `Poll[T]`

The result of polling a future: either a value is ready, or the future needs
to be polled again later.

```
enum Poll[T]:
    Ready(T)
    Pending
```

`Poll` is a simple enum. No special compiler support.

### 2.2 `Future` trait

A value that asynchronously produces a result. Polled to completion by a
reactor or the fiber runtime.

```
trait Future:
    type Output
    fn poll(mut self, cx: &Context) -> Poll[Self.Output]
```

**Differences from Rust:**

| | Rust | With |
|---|---|---|
| Self parameter | `Pin<&mut Self>` | `mut self` |
| Context mutability | `&mut Context` | `&Context` |
| Pin requirement | Required (self-referential) | Absent (no stored references) |

`mut self` means the future can transition between states (change its own
enum variant) during poll. Since With futures cannot be self-referential,
they can always be moved safely. No `Pin`, no `Unpin`, no `PhantomPinned`.

**The contract:**

1. After `poll` returns `Ready(value)`, the future must not be polled again.
   Doing so is a logic error (may panic in debug builds).
2. After `poll` returns `Pending`, the future MUST have arranged for the
   waker to be called eventually. Failure to do so causes the future to
   hang permanently.
3. `poll` must not block. It must return quickly. Long-running computation
   should be offloaded to a blocking thread pool.

### 2.3 `Waker`

An opaque handle that tells the reactor "this future is ready to be polled
again." Internally, it's a vtable-dispatched callback.

```
type Waker:
    fn wake(self)
    fn wake_by_ref(&self)
    fn clone(&self) -> Waker
```

Users never construct Wakers. They receive one from `Context` and call
`.wake()` when their I/O source becomes ready. The reactor and the
`into_task` bridge each provide their own Waker implementations.

**Why vtable despite "one scheduler":**

With has one fiber scheduler, but `std.async.sm` has two poll-drivers:
`SmReactor` (standalone) and the fiber bridge (`into_task`). The vtable
lets both provide wakers through the same `Context` type without the
future knowing which driver is polling it.

### 2.4 `Context`

Passed to `Future.poll`. Carries the waker for the current poll cycle.

```
type Context:
    waker: &Waker

fn Context.waker(&self) -> &Waker:
    self.waker
```

Minimal by design. No executor reference, no task-local storage, no
budgeting. Just a waker.

### 2.5 `RawWaker` (internal)

The vtable-based internal representation. Not exposed to users.

```
// Internal to std.async.sm
type RawWaker {
    data: *mut u8,
    vtable: *const RawWakerVTable,
}

type RawWakerVTable {
    clone: fn(*mut u8) -> RawWaker,
    wake: fn(*mut u8),
    wake_by_ref: fn(*mut u8),
    drop: fn(*mut u8),
}
```

This is a direct port of Rust's `RawWaker`/`RawWakerVTable`. The stdlib
provides two implementations:

1. **Reactor waker:** Stores the future's slot index in the reactor's slab.
   `wake()` marks the slot as ready and signals the reactor's event loop.

2. **Fiber bridge waker:** Stores a fiber handle. `wake()` schedules the
   fiber for resumption on the fiber scheduler.

---

## 3. Bridge: `into_task`

The critical interop function. Wraps any `Future` in a `Task[T]` that
fibers can `.await`.

```
fn into_task[F: Future](f: F) -> Task[F.Output]
```

**Semantics:**

1. Allocates a task slot on the fiber scheduler.
2. Stores the future in the slot.
3. Returns a `Task[F.Output]` handle.
4. When a fiber calls `.await` on the task, the scheduler polls the future
   instead of suspending a fiber stack.
5. If `poll` returns `Pending`, the scheduler parks the task. The waker
   will re-enqueue it when I/O is ready.
6. If `poll` returns `Ready(value)`, the scheduler resumes the awaiting
   fiber with the value.

**Cancellation:** Dropping a `Task` that wraps a future drops the future.
No cleanup callbacks, no unwind. The future's destructor runs (freeing
buffers, closing sockets), and the task slot is reclaimed. This matches
Rust's cancellation semantics: stop polling = cancel.

**Memory:**

```
Task[T] overhead:     16 bytes (handle + status)
Fiber stack overhead: 8,192 bytes minimum

into_task saves:      ~8,176 bytes per concurrent operation
At 100K connections:  ~780 MB saved
```

**From the caller's perspective, `into_task` is invisible:**

```
async fn handler(conn: Connection):
    // The caller doesn't know or care whether this Task
    // is backed by a fiber or a state machine
    let resp = fetch_data(conn).await
    process(resp)

fn fetch_data(conn: Connection) -> Task[Data]:
    // Could be: spawn(async fn ...) — fiber-backed
    // Could be: into_task(FetchState.new(conn)) — state-machine-backed
    // The return type is the same either way
    into_task(FetchState.new(conn))
```

---

## 4. Standalone Reactor: `SmReactor`

For workloads that don't need fibers at all — pure state-machine event loops
running on an OS thread.

```
type SmReactor

fn SmReactor.new() -> SmReactor
fn SmReactor.register[F: Future](mut self, f: F) -> FutureHandle
fn SmReactor.cancel(mut self, handle: FutureHandle)
fn SmReactor.run(mut self)                        // block until all futures complete
fn SmReactor.run_until_idle(mut self) -> i32      // poll all ready futures, return count
fn SmReactor.active_count(&self) -> i32           // number of incomplete futures
```

**`SmReactor` is NOT the fiber scheduler.** It's a separate, simpler event
loop that only manages state-machine futures. It runs on whatever thread
calls `.run()`. It does not interact with the fiber runtime.

**Use case:** A dedicated proxy, load balancer, or connection pool where
every connection is a simple state machine and you want maximum density
with minimum overhead.

```
fn main:
    let listener = TcpListener.bind("0.0.0.0:8080")
    let reactor = SmReactor.new()

    for conn in listener:
        reactor.register(HttpHandler.new(conn))
        // Periodically drain completed futures
        if reactor.active_count() > 1000:
            reactor.run_until_idle()

    reactor.run()  // drain remaining
```

**Backpressure:** `SmReactor` does not provide implicit backpressure.
When a future produces data faster than its consumer can handle, the
future must manage flow control explicitly:

```
enum ProducerState:
    Reading(Source, Sink)
    WaitingForDrain(Source, Sink)

impl Future for ProducerState:
    type Output = ()
    fn poll(mut self, cx: &Context) -> Poll[()]:
        match self
            .Reading(src, sink) =>
                let data = src.poll_read(cx)?
                if sink.is_full():
                    sink.register_drain_waker(cx.waker().clone())
                    self = .WaitingForDrain(src, sink)
                    .Pending
                else:
                    sink.push(data)
                    .Pending
            .WaitingForDrain(src, sink) =>
                if sink.is_full(): return .Pending
                self = .Reading(src, sink)
                .Pending
```

This is the explicit cost of state machines. Fibers handle backpressure
naturally (blocking on a full channel suspends the fiber). State machines
require manual flow control. The docs should make this trade-off clear.

---

## 5. I/O Readiness

State machines need non-blocking I/O primitives that report readiness
instead of blocking.

### 5.1 Poll-based I/O

```
// Provided by std.io for use with state machines
fn TcpStream.poll_read(mut self, buf: &mut Buffer, cx: &Context) -> Poll[Result[usize, IoError]]
fn TcpStream.poll_write(mut self, data: &[u8], cx: &Context) -> Poll[Result[usize, IoError]]
fn TcpStream.poll_ready(&self, cx: &Context) -> bool
fn TcpListener.poll_accept(mut self, cx: &Context) -> Poll[Result[TcpStream, IoError]]
```

These are non-blocking wrappers around the platform's I/O. If the operation
would block, they register the waker with the platform's event system
(epoll/kqueue/IOCP) and return `Pending`. When the file descriptor becomes
ready, the event system calls `waker.wake()`, which re-enqueues the future
for polling.

### 5.2 Timer

```
fn poll_sleep(deadline: Instant, cx: &Context) -> Poll[()]
```

Registers a timer with the reactor. Returns `Ready(())` when the deadline
has passed.

### 5.3 Platform Event Loop

Both `SmReactor` and the `into_task` bridge need a platform event loop.
The fiber runtime already has one (for fiber-based async I/O). The
`SmReactor` has its own:

```
// Internal to SmReactor
type EventLoop {
    // Platform-specific: epoll on Linux, kqueue on macOS/BSD, IOCP on Windows
    poll_fd: i32,
    events: Vec[Event],
    timers: BinaryHeap[TimerEntry],
}
```

The `into_task` bridge reuses the fiber runtime's event loop. When a
state-machine future registers interest in a file descriptor, the waker
is plumbed into the fiber scheduler's existing I/O poller.

---

## 6. Combinators

A small set of utility futures for common patterns. These are functions
that return futures, not methods on a trait.

```
// Wait for the first future to complete, cancel the other
fn select[A: Future, B: Future](a: A, b: B) -> Future[Either[A.Output, B.Output]]

// Wait for both futures to complete
fn join[A: Future, B: Future](a: A, b: B) -> Future[(A.Output, B.Output)]

// Wrap a value in a future that's immediately ready
fn ready[T](value: T) -> Future[T]

// A future that's never ready (useful for select timeouts)
fn pending[T]() -> Future[T]

// Race a future against a deadline
fn timeout[F: Future](f: F, deadline: Instant) -> Future[Result[F.Output, TimeoutError]]
```

**No `FutureExt` trait.** Combinators are free functions, not methods.
This avoids polluting every `Future` implementor with a long method chain
and keeps the trait minimal. Usage:

```
use std.async.sm.{select, timeout}

let result = into_task(
    timeout(FetchState.new(conn), Instant.now() + Duration.seconds(30))
).await
```

---

## 7. What Is Explicitly NOT Included

### 7.1 No `async fn` for state machines

There is no way to write:

```
// NOT supported — this is fiber-based async, not state-machine
sm_async fn fetch(url: str) -> Response:
    let conn = connect(url).sm_await
    conn.read_response().sm_await
```

State machines are hand-written enums. This is deliberate:

1. A macro or keyword that generates state machines from sequential code
   is a mini-compiler that must reject references across suspend points —
   adding complexity for sugar.
2. The verbosity of hand-written state machines is a signal: "you're a
   power user solving a scaling problem." If state machines were as easy
   as fibers, people would use them when they don't need them, creating
   the ecosystem split With is designed to avoid.
3. Debugging a hand-written state machine is trivial — you can print the
   current state, match on it, serialize it. Debugging a generated one
   requires understanding the generator's output.

### 7.2 No `Pin`

With's core invariant (no stored references in structs) makes `Pin`
unnecessary. Futures can always be moved. There is no `Unpin` trait,
no `PhantomPinned`, no `pin!` macro, no `Pin<&mut Self>`.

This is the single biggest ergonomic win over Rust's async model.

### 7.3 No `Stream` / `AsyncIterator`

Async iteration over state machines is not included in v1. If needed
later, it would be:

```
trait Stream:
    type Item
    fn poll_next(mut self, cx: &Context) -> Poll[Option[Self.Item]]
```

Deferred because: (a) the use case (async iteration in a state machine)
is rare — most high-density workloads are request-response, not streaming,
and (b) fibers handle async iteration naturally with channels.

### 7.4 No custom executors

`SmReactor` is the one standalone reactor. `into_task` is the one bridge
to fiber-land. There is no `Executor` trait, no pluggable runtimes, no
`block_on`. This matches With's Invariant 3: one scheduler, not pluggable.

---

## 8. Implementation Notes

### 8.1 File Structure

```
lib/std/async/sm/
├── mod.w              // re-exports
├── future.w           // Future trait, Poll enum
├── waker.w            // Waker, RawWaker, RawWakerVTable, Context
├── bridge.w           // into_task implementation
├── reactor.w          // SmReactor
├── combinators.w      // select, join, timeout, ready, pending
└── io.w               // poll_read, poll_write, poll_accept adapters
```

### 8.2 `RawWaker` Implementation

The vtable pattern uses function pointers, matching Rust's approach:

```
fn raw_waker_new(data: *mut u8, vtable: *const RawWakerVTable) -> RawWaker:
    RawWaker { data, vtable }

fn waker_from_raw(raw: RawWaker) -> Waker:
    // Waker wraps RawWaker, provides safe interface
    Waker { raw }

fn Waker.wake(self):
    let raw = self.raw
    (raw.vtable.wake)(raw.data)

fn Waker.clone(&self) -> Waker:
    let raw = self.raw
    waker_from_raw((raw.vtable.clone)(raw.data))
```

**Reactor waker implementation:**

```
// data = pointer to ReactorSlot { reactor: *mut SmReactor, index: u32 }
fn reactor_waker_wake(data: *mut u8):
    let slot = data as *mut ReactorSlot
    slot.reactor.mark_ready(slot.index)
    slot.reactor.signal_event_loop()

fn reactor_waker_clone(data: *mut u8) -> RawWaker:
    let slot = data as *mut ReactorSlot
    // Increment refcount, return new RawWaker pointing to same slot
    slot.refcount += 1
    raw_waker_new(data, &REACTOR_VTABLE)
```

**Fiber bridge waker implementation:**

```
// data = fiber handle (from the fiber scheduler)
fn fiber_waker_wake(data: *mut u8):
    let fiber_handle = data as FiberHandle
    runtime::schedule_fiber(fiber_handle)

fn fiber_waker_clone(data: *mut u8) -> RawWaker:
    let fiber_handle = data as FiberHandle
    raw_waker_new(data, &FIBER_VTABLE)
```

### 8.3 `SmReactor` Internals

```
type SmReactor {
    // Slab allocator for futures — O(1) insert/remove
    futures: SlabMap[FutureHandle, ErasedFuture],
    ready_queue: Vec[FutureHandle],       // futures to poll this iteration

    // Platform event loop
    poll_fd: i32,                          // epoll_create / kqueue
    events: Vec[PlatformEvent],
    timers: Vec[TimerEntry],               // sorted by deadline
}

type ErasedFuture {
    // Type-erased future storage
    data: *mut u8,
    poll_fn: fn(*mut u8, &Context) -> Poll[()],
    drop_fn: fn(*mut u8),
    size: usize,
}
```

**Type erasure:** `SmReactor` stores heterogeneous futures. Each future
is heap-allocated and accessed through a poll function pointer. The
reactor doesn't know or care about the concrete future type.

**Event loop:**

```
fn SmReactor.run(mut self):
    while self.futures.len() > 0:
        // 1. Poll all ready futures
        while self.ready_queue.len() > 0:
            let handle = self.ready_queue.pop()
            let future = self.futures.get_mut(handle)
            let waker = self.make_waker(handle)
            let cx = Context { waker: &waker }
            match (future.poll_fn)(future.data, &cx)
                Poll.Ready(()) =>
                    (future.drop_fn)(future.data)
                    self.futures.remove(handle)
                Poll.Pending =>
                    pass  // waker will re-enqueue when ready

        // 2. Wait for I/O events
        let timeout = self.next_timer_deadline()
        let n = platform_poll(self.poll_fd, &mut self.events, timeout)

        // 3. Fire expired timers
        self.fire_timers()

        // 4. Process I/O events → wake futures
        for i in 0..n:
            let fd = self.events[i].fd
            let handle = self.fd_to_future[fd]
            self.ready_queue.push(handle)
```

### 8.4 `into_task` Internals

```
fn into_task[F: Future](f: F) -> Task[F.Output]:
    // 1. Allocate a task slot on the fiber scheduler
    let task_id = runtime::alloc_task_slot()

    // 2. Store the future in the slot (type-erased)
    let erased = erase_future(f)
    runtime::set_task_future(task_id, erased)

    // 3. Mark the task as "future-backed" (not fiber-backed)
    runtime::set_task_kind(task_id, TaskKind.Future)

    // 4. Enqueue for initial poll
    runtime::enqueue_task(task_id)

    // 5. Return task handle
    Task.from_id(task_id)
```

When the fiber scheduler encounters a future-backed task in its run queue,
it polls the future instead of resuming a fiber:

```
// Inside the fiber scheduler's run loop
fn scheduler_step(task_id: TaskId):
    match runtime::task_kind(task_id)
        TaskKind.Fiber =>
            // Normal path: switch to fiber stack
            fiber_resume(task_id)
        TaskKind.Future =>
            // State machine path: poll in place, no stack switch
            let future = runtime::get_task_future(task_id)
            let waker = make_fiber_waker(task_id)
            let cx = Context { waker: &waker }
            match future.poll(&cx)
                Poll.Ready(value) =>
                    runtime::complete_task(task_id, value)
                Poll.Pending =>
                    pass  // waker will re-enqueue
```

### 8.5 Platform I/O Integration

**Linux (epoll):**
```
fn register_readable(fd: i32, waker: Waker):
    epoll_ctl(epoll_fd, EPOLL_CTL_ADD, fd, EPOLLIN | EPOLLET)
    // Store waker in fd→waker map
```

**macOS/BSD (kqueue):**
```
fn register_readable(fd: i32, waker: Waker):
    kevent(kq, EV_SET(fd, EVFILT_READ, EV_ADD | EV_ONESHOT))
```

**Windows (IOCP):**
```
fn register_readable(handle: HANDLE, waker: Waker):
    CreateIoCompletionPort(handle, iocp, key, 0)
```

The platform abstraction lives in `std.io.event_loop` (shared with the
fiber runtime). `std.async.sm.io` builds poll-based adapters on top.

### 8.6 Memory Layout Comparison

```
// Fiber-based handler: 8KB+ per connection
async fn handle(conn: Connection) -> Response:
    // Stack: 8,192 bytes (minimum fiber stack)
    // + Task metadata: 64 bytes
    // Total: ~8,256 bytes per connection

// State machine handler: ~64-256 bytes per connection
enum HttpHandler:
    ReadingHeaders(TcpStream, HeaderBuffer)    // ~128 bytes
    ReadingBody(TcpStream, HeaderBuffer, Body) // ~256 bytes
    Responding(TcpStream, Response)            // ~128 bytes
// + ErasedFuture metadata: 32 bytes
// + reactor slot: 16 bytes
// Total: ~176-304 bytes per connection

// At 100K connections:
// Fibers:         100,000 × 8,256 = 790 MB
// State machines: 100,000 × 304   =  29 MB
```

---

## 9. Documentation Guidance

The module docs should open with:

> **You probably want fibers.** The fiber runtime handles the vast majority
> of async workloads with excellent ergonomics. Use `async fn`, `.await`,
> and `spawn`.
>
> This module exists for one specific case: you need very high connection
> density (100K+) and you've measured that fiber stack memory is the
> bottleneck. You're trading ergonomics for memory efficiency.
>
> **Trade-offs:**
> - No references across suspend points (use owned values and handles)
> - No implicit backpressure (manage flow control manually)
> - Verbose state transitions (hand-written enum + match)
> - Debugging requires understanding your state machine's transitions
>
> **When to use this:**
> - Proxies, load balancers, connection pools
> - 100K+ concurrent mostly-idle connections
> - Simple request-response patterns
>
> **When NOT to use this:**
> - Complex business logic with many suspend points
> - Code that needs references across async boundaries
> - Anything under 10K concurrent connections

Include a benchmark comparing fibers vs state machines at 1K, 10K, 100K,
and 500K connections — memory usage, throughput, and latency. Let the
numbers make the case.

---

## 10. Implementation Order

| Phase | What | Depends on |
|-------|------|-----------|
| 1 | `Future` trait, `Poll` enum, `Context`, `Waker` | Nothing |
| 2 | `SmReactor` with epoll/kqueue | Phase 1 |
| 3 | `into_task` bridge | Phase 1 + fiber runtime internals |
| 4 | Poll-based I/O adapters | Phase 2 + `std.io` |
| 5 | Combinators (`select`, `join`, `timeout`) | Phase 1 |
| 6 | Documentation + benchmarks | All phases |

Phase 1 is pure library code — no compiler changes, no runtime changes.
Phase 3 is the only part that touches the fiber scheduler internals.

**Estimated scope:** ~1,500 lines across 7 files. No compiler changes.

---

*State machine async — v1.0*