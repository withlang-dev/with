# Example: User Service

A multi-layered REST API for user management. Demonstrates how With handles
real-world backend architecture: dependency injection via trait objects,
cache-through patterns, structured concurrency, graceful shutdown, and
testability with mocks.

## Files

```
src/
├── main.with          Entry point — server setup, dependency wiring, graceful shutdown
├── domain.with        Domain types: User, UserProfile, Role, Notification
├── errors.with        Error hierarchy: DbError, CacheError, NotifyError → ServiceError
├── traits.with        Trait definitions: UserRepository, CacheService, NotificationService, AuditLog
├── service.with       Business logic: UserService with builder, CRUD, cache-through, batch ops
├── http.with          HTTP routing and request/response handling
├── tests.with         Full test suite with in-memory mocks
├── repo/
│   └── postgres.with  PostgreSQL implementation of UserRepository
├── cache/
│   └── redis.with     Redis implementation of CacheService
└── notify/
    └── email.with     SMTP implementation of NotificationService
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

**Error hierarchy with From conversions** — `error ServiceError from DbError, CacheError,
NotifyError =` generates the wrappers and conversions that let `?` propagate across subsystem
boundaries, and declares the service's own variants beside them.

**Testability** — `MockUserRepo`, `MockCache`, `MockNotifier` implement the same traits.
`NotificationLog = Arc[Mutex[List[Notification]]]` gives tests a handle to assert on side effects.

## Language Features

| Feature | Spec | Location |
|---------|------|----------|
| `async fn` returns `Task[T]` | §14.4 | Throughout |
| `async scope` + `s.track()` | §14.9 | main.with, service.with |
| `select await` branched racing | §14.10 | main.with — shutdown, with_timeout |
| `task.cancel()` cooperative cancellation | §14.7 | main.with — with_timeout |
| Trait objects (`Box[dyn T]`) | §11.4 | service.with — all dependencies |
| `with` blocks (guarded) | §7.1 | service.with, tests.with — lock access |
| `with` blocks (binding) | §7.3 | service.with — describe_changes; repo/postgres.with |
| Record update `{ x with field: val }` | §7.4 | service.with — builder, partial user updates |
| Method chaining on by-value self | §9.5 | main.with — builder |
| Pipeline operators `\|>` | §9.8 | service.with — batch fetch |
| Error enums with `From` | §10.7 | errors.with — cross-subsystem propagation |
| `?` propagation | §10.2 | Throughout |
| `??` coalescing | §10.3 | service.with — `find_by_id()?? return Err(...)` |
| Default field values | §4.3 | domain.with, service.with |
| `.Variant` shorthand + auto accessors | §4.4 | Throughout |
| Distinct types | §4.5 | domain.with — `type UserId = distinct i64` |
| String interpolation | §15 | Throughout |
| `@[derive(Clone)]` | §11.8 | domain.with — User, CreateUserRequest |
| `@[derive(all)]` | §11.8 | domain.with — Role, Priority |
| Default field values (`= None`) | §4.3 | domain.with — UserUpdate partial-update fields |
| `?.` optional chaining | §10.3 | tests.with — `profile.last_login?.elapsed()` |
| `.context()` / `.with_context()` | §10.6 | main.with — `load_config_from_file` error wrapping |
| Enum accessor methods (`.is_X()`, `.as_X_ref()`) | §4.4 | tests.with — `role.is_admin()`, `err.as_validation_ref()` |
| `let...else` | §9.7 | service.with — `update_user` refutable pattern |
| `assert_matches` | §10 | tests.with — pattern-based assertions |

## `with` Usage Census

| Form | Locations |
|------|-----------|
| **Form 1: Guarded** (Scoped/ScopedMut) | service.with — metrics lock; tests.with — notification log |
| **Form 2: Implicit builder return** (§7.2) | notify/email.with — SmtpMessage construction |
| **Form 3: Binding** (scoped name) | service.with — describe_changes; repo/postgres.with — SET clauses |
| **Form 4: Record update** | service.with — builder setters, partial user updates |

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
