# 14.17 Synchronization Primitives

- `Mutex[T]` — mutual exclusion with scoped access
- `RwLock[T]` — reader-writer lock with scoped access
- `Atomic[T]` — lock-free atomic operations
- `Condvar` — condition variable
- `Barrier` — reusable fixed-party barrier
- `Once` — one-time initialization

All are usable with `with` blocks for scoped access. Lock operations
are fiber-aware: contended locks yield the fiber, not the OS thread.
Any synchronization primitive that can yield the current fiber must be
represented in `may_suspend` analysis, either as a direct
scheduler-yielding operation or as an operation returning a `Task` that
suspends only when awaited.

`Condvar.wait(lock)` is the one standard-library exception to the
ordinary no-await-guard rule for lock guards: it must be called while
holding the associated `Mutex[T]` guard, atomically registers the waiter,
releases that mutex, yields the current fiber until notified, then
reacquires the mutex before returning. The exception applies only to the
guard produced by the same lock argument; any unrelated live
`@[no_await_guard]` value still makes the wait a compile error. Code must
wait in a predicate loop because wakeups may be spurious.

`Condvar.notify_one()` wakes at least one currently registered waiter when
one exists; `Condvar.notify_all()` wakes all waiters registered at the
time of notification. Notifications are not stored when no waiter is
registered.

`Barrier.wait()` yields the current fiber until the configured number of
participants reaches the barrier generation. The last participant advances
the generation and receives `true`; the others receive `false`. Barriers
are reusable.

`Once.call_once(init)` runs `init` at most once after a successful
completion. If `init` panics and execution resumes, the `Once` resets to
the uninitialized state so a later call retries instead of poisoning the
value permanently.
