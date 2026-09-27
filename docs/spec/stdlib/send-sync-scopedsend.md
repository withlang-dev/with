# 14.16 Send, Sync, and ScopedSend

- `Send`: safe to transfer across thread boundaries (value may
  outlive the sender). Ephemeral types are **not** `Send`.
- `Sync`: safe to share via `&T` across threads
- `ScopedSend`: safe to **capture in a closure** sent to a scoped
  thread or fiber that is guaranteed to join before the current
  scope exits.
  All `Send` types implement `ScopedSend`. **Ephemeral types also
  implement `ScopedSend`** — they can be captured by scoped fibers
  because the scope guarantees the fiber joins before the borrowed
  data goes out of scope.

  **Important:** `ScopedSend` does NOT mean "safe to send over a
  channel." Channels decouple sender and receiver lifetimes.
  `ScopedSend` only covers direct capture in the spawned closure —
  the reference's lifetime is guaranteed by the scope's join.
  Channel element types require full `Send` (see §14.15).

```
// thread.spawn_os requires Send — no ephemerals
thread.spawn_os(() => use_ref(&local))   // ERROR: &local is not Send

// scope requires ScopedSend — ephemerals allowed
scope s =>
    s.spawn(() => use_ref(&local))       // OK: ScopedSend, joins before scope exits

// async scope requires ScopedSend — ephemerals allowed
async scope s =>
    s.track(process(&local))          // OK: ScopedSend, tracked task joins
```

| Type | `Send` | `ScopedSend` |
|------|--------|--------------|
| `i32`, `String`, owned types | Yes | Yes |
| `Arc[T]` where `T: Send + Sync` | Yes | Yes |
| `Rc[T]` | No | No |
| `&T` | No | Yes |
| Ephemeral structs | No | Yes |
| `Task[T]` (non-ephemeral) | Yes (if `T: Send`) | Yes |
| `Task[T]` (ephemeral) | No | Yes |
