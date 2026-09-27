# 14.19 Fiber Stack Management

Each fiber has a dedicated stack. Stack memory is the primary resource
cost of the fiber model and must be understood to use `async`
effectively.

**Conforming baseline: fixed-size pooled stacks.** Each fiber gets a
fixed-size stack (default 64 KB unless configured) with a guard page; stacks are
recycled through a pool, so fiber creation is a pool grab, not an
allocation. Stack overflow faults on the guard page — it never
silently corrupts memory. This is the reference implementation's
model and the behavior programs may rely on. Stack sizing is
implementation-defined configuration. The reference implementation
reads the optional `[runtime]` `with.toml` section:

```toml
[runtime]
fiber_stack_size = 131072
fiber_pool_size = 64
fiber_worker_count = 4
```

All three values are positive integers. Missing keys use implementation
defaults. `fiber_stack_size` sets the default stack size for fibers
whose call site does not provide an explicit stack size; an explicit
`@[stack_size(N)]` on an async function has higher priority.
`fiber_pool_size` caps the number of completed fiber stacks retained
for reuse; stacks completed beyond the cap are released instead of
cached. `fiber_worker_count` selects the number of OS-worker threads
participating in the standard scheduler; `1` preserves single-worker
cooperative behavior, values greater than one enable cross-thread
work stealing. Implementations may define an upper bound and must reject
unsupported worker counts loudly rather than silently running fewer
workers. Runtime configuration is applied before the runtime is
initialized and before the first fiber spawn.

**Growable stacks (roadmap, implementation-defined):** an
implementation may start fibers on a smaller initial allocation and
grow on demand, provided growth is detected safely (e.g. stack
probes) and §14.13's semantic stack preservation holds. Growth is an
optimization, never an observable semantic — programs must be
correct under the fixed-size baseline.

**FFI stack headroom:** C code called via `c_import` has no knowledge
of With's fiber stacks and may exceed remaining stack space. Under
the fixed-size baseline, the 64 KB default provides the headroom for
typical C calls; fibers driving deep C call trees should be sized via
`fiber_stack_size`.

**FFI stack switching (roadmap, implementation-defined):** an
implementation may instead switch to an OS-thread-sized stack at the
FFI boundary:

1. The compiler marks functions as `ffi_reachable` if they (directly
   or transitively) call any `c_import` function.
2. At the FFI call site, the runtime saves the fiber stack pointer
   and switches to a pre-allocated OS-thread stack (typically 2–8 MB)
   from a per-thread pool.
3. The C function executes on the full-size stack.
4. On return, the runtime restores the fiber stack pointer.

The stack switch costs approximately 10–50 ns (save/restore a few
registers) — honest overhead: not zero-cost, but predictable and
safe. Pure-With fibers that never call C code pay nothing. The
`@[ffi_stack]` attribute is reserved for this mode: it forces an
entire function to run on an OS-thread stack, avoiding per-call
switching. Neither the switching nor the attribute is part of the
conforming baseline.

**No suspension while C frames are on the stack.** If C code calls
back into With (e.g., via a function pointer passed to `qsort`),
the With callback **must not suspend**. Suspending a fiber while C
frames are active on the OS stack would corrupt the stack — another
fiber resuming on the same OS thread would overwrite the paused C
frames.

The compiler enforces this via `may_suspend` analysis (Invariant 5,
§14.3): any function used as an `extern "C"` callback, or
transitively called while C frames are on the stack, must not be
`may_suspend`:

```
// ERROR: callback must not suspend
unsafe { c_sort(items.ptr, items.len, (a, b) =>
    fetch_weight(a).await <=> fetch_weight(b).await
    //              ^^^^^^ ERROR: may_suspend in extern "C" callback
) }

// OK: no suspension in callback
unsafe { c_sort(items.ptr, items.len, (a, b) =>
    a.weight <=> b.weight
) }

// OK: start a detached task (no .await needed)
unsafe { c_on_event(event =>
    handle_event(copy_event(event))   // detached if both checks pass
) }
```

**Memory budget:**

| Model | Per-task overhead | 100K concurrent tasks |
|-------|------------------|----------------------|
| Rust stackless futures | ~state machine size | ~state machine sizes |
| With fibers (64 KB pooled) | 64 KB virtual per fiber | ~6.4 GB virtual / resident scales with touched pages |
| OS threads (8 MB typical) | ~8 MB | Not viable |

The headline number is virtual address space, not resident memory —
a fiber's resident cost is only the stack pages it has actually
touched. Realistic suspended fibers doing typical I/O work often use
less than 2 KB of actual stack. (A growable-stack implementation,
§14.19 roadmap, reduces the virtual footprint too.)

**Fiber stack pooling:** The runtime maintains a pool of
pre-allocated fiber stacks. Creating a fiber grabs a stack from the
pool (one atomic operation, not `malloc`). When a fiber exits, its
stack is returned to the pool for reuse. This makes fiber
creation/destruction extremely cheap — comparable to grabbing an
object from a free list.

This is critical for async trait dispatch: calling
`repo.find_by_id(id).await` through a `Box[dyn UserRepository]`
creates and destroys a fiber, but the stack is recycled from the
pool. The cost is a pool grab + context switch, not a heap
allocation.

Pool size is configurable. The runtime lazily grows the pool as
needed and may shrink it under memory pressure.

**Scale guidance:** Fibers are appropriate for web servers and
database backends targeting 10K–100K concurrent connections. For
systems requiring millions of simultaneous in-flight tasks, collect
into owned data structures and process with a smaller fixed pool of
worker fibers. For >100K suspended tasks, prefer channel-driven
worker pool architectures.
