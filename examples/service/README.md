# Example: User Service

A multi-layered REST API for user management. Demonstrates how With handles
real-world backend architecture: dependency injection via trait objects,
cache-through patterns, structured concurrency, graceful shutdown, and
testability with mocks.

## Files

```
src/
├── main.w          Entry point — server setup, dependency wiring, graceful shutdown
├── domain.w        Domain types: User, UserProfile, Role, Notification
├── errors.w        Error hierarchy: DbError, CacheError, NotifyError → ServiceError
├── traits.w        Trait definitions: UserRepository, CacheService, NotificationService, AuditLog
├── service.w       Business logic: UserService with builder, CRUD, cache-through, batch ops
├── http.w          HTTP routing and request/response handling
├── tests.w         Full test suite with in-memory mocks
├── repo/
│   └── postgres.w  PostgreSQL implementation of UserRepository
├── cache/
│   └── redis.w     Redis implementation of CacheService
└── notify/
    └── email.w     SMTP implementation of NotificationService
```

## What It Demonstrates

**Structured concurrency with graceful shutdown** — The main loop uses `async scope`
to manage connection fibers. On SIGTERM, `select await` fires the shutdown branch,
breaking the accept loop; the scope cancels all children and waits for cleanup.

**Timeout with task cancellation** — `with_timeout[T]` uses `select await` to race
work against a timer, demonstrating cooperative cancellation with guaranteed destructor
cleanup.

**Trait objects for dependency injection** — The service takes `Box[dyn UserRepository]`,
`Box[dyn CacheService]`, etc. Tests swap in mocks without changing a line of business logic.

**Builder pattern with method chaining** — `UserService.builder()` returns a builder whose
setters take `self` by value (§9.5), enabling dot-notation chaining without naming the
intermediate builder type.

**Cache-through with structured concurrency** — `get_profile()` checks cache, then on miss
fetches the user and fires off three parallel enrichment queries (`count_posts`, `count_followers`,
`last_login`) inside an `async scope`.

**Error hierarchy with From conversions** — `ServiceError` wraps `DbError`, `CacheError`, and
`NotifyError` via `impl From`, enabling `?` propagation across subsystem boundaries.

**Testability** — `MockUserRepo`, `MockCache`, `MockNotifier` implement the same traits.
`NotificationLog = Arc[Mutex[Vec[Notification]]]` gives tests a handle to assert on side effects.

## Language Features

| Feature | Spec | Location |
|---------|------|----------|
| `async fn` returns `Task[T]` | §14.4 | Throughout |
| `async scope` + `s.track()` | §14.8 | main.w, service.w |
| `select await` branched racing | §14.9 | main.w — shutdown, with_timeout |
| `task.cancel()` cooperative cancellation | §14.6 | main.w — with_timeout |
| Trait objects (`Box[dyn T]`) | §11.4 | service.w — all dependencies |
| `with` blocks (guarded) | §7.1 | service.w, tests.w — lock access |
| `with` blocks (binding) | §7.3 | service.w — describe_changes; repo/postgres.w |
| Record update `{ x with field: val }` | §7.4 | service.w — builder, partial user updates |
| Method chaining on by-value self | §9.5 | main.w — builder |
| Pipeline operators `\|>` | §9.8 | service.w — batch fetch |
| Error enums with `From` | §10.7 | errors.w — cross-subsystem propagation |
| `?` propagation | §10.2 | Throughout |
| `??` coalescing | §10.3 | service.w — `find_by_id()?? return Err(...)` |
| Default field values | §4.3 | domain.w, service.w |
| `.Variant` shorthand + auto accessors | §4.4 | Throughout |
| Distinct types | §4.5 | domain.w — `type UserId = distinct i64` |
| String interpolation | §15 | Throughout |
| `assert_matches` | §10 | tests.w — pattern-based assertions |

## `with` Usage Census

| Form | Locations |
|------|-----------|
| **Form 1: Guarded** (Scoped/ScopedMut) | service.w — metrics lock; tests.w — notification log |
| **Form 2: Implicit builder return** (§7.2) | notify/email.w — SmtpMessage construction |
| **Form 3: Binding** (scoped name) | service.w — describe_changes; repo/postgres.w — SET clauses |
| **Form 4: Record update** | service.w — builder setters, partial user updates |

This matches the expected distribution in real service code: most
`with` blocks are guarded access to locks, connections, and caches.

## Cancellation Flow

What happens when SIGTERM arrives:

```
SIGTERM received
  └─ listen_for_shutdown() completes
      └─ select await in main fires the shutdown branch
          └─ break exits accept loop
              └─ async scope begins cancellation
                  ├─ connection handler fiber 1:
                  │   └─ awaiting handle_request() → cancellation flag set
                  │       └─ reaches next await → begins unwinding
                  │           ├─ conn: TcpStream dropped → socket closed
                  │           ├─ db connection dropped → returned to pool
                  │           └─ lock guard (if held) dropped → lock released
                  ├─ connection handler fiber 2: (same)
                  └─ all children completed
                      └─ async scope returns
                          └─ main() prints "shut down cleanly"
```

Every resource is cleaned up by destructors. No explicit cleanup code.
No `finally` blocks. No `defer`. Ownership handles it.

The key invariant: **`with` blocks guarantee the guard is released even
under cancellation**, because cancellation triggers unwinding, and
unwinding runs destructors. This is why `with` + async + ownership is
a powerful combination — resource safety composes with concurrency safety.
