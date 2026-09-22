# Async Service Example — Tour Guide

This example implements a user management API backend in With. It
demonstrates how trait objects, async methods, `with` blocks, and
structured concurrency compose into a clean, production-style
service architecture.

The pattern is dependency injection via trait objects — the same
architecture you'd build in Go (interfaces), Rust (dyn Trait), or
Java (interfaces + Spring). In With, it works with zero special
machinery because `async fn` in traits just returns `Task[T]`, and
trait objects with `Task[T]` return types need no boxing.

> **Source code:** [`examples/service/src/`](../examples/service/src/)
> All code lives in `.w` files there. This document is a reading companion, not a copy.

---

## Architecture Overview

```
┌─────────────┐
│   main.w    │  Server startup, dependency wiring, graceful shutdown
├─────────────┤
│   http.w    │  HTTP routing — maps requests to service calls
├─────────────┤
│  service.w  │  Business logic: CRUD, cache-through, batch ops, builder
├─────────────┤
│  traits.w   │  Trait definitions (the seams): UserRepository, CacheService, etc.
├─────────────┤
│  domain.w   │  Domain types: User, Role, Notification, UserUpdate
│  errors.w   │  Error hierarchy: DbError, CacheError, NotifyError → ServiceError
├─────────────┤
│ repo/       │  PostgreSQL implementation of UserRepository
│ cache/      │  Redis implementation of CacheService
│ notify/     │  SMTP implementation of NotificationService
├─────────────┤
│  tests.w    │  Full test suite with in-memory mocks
└─────────────┘
```

**Domain layer** (`domain.w`, `errors.w`) — Pure data types and error enums. No behavior, no I/O. `User`, `Role`, `UserUpdate`, `Notification`, and a unified `ServiceError` with `from` shorthand for automatic `?` propagation across subsystem boundaries.

**Trait layer** (`traits.w`) — Four async traits define the service seams. Every dependency is a `Box[dyn Trait]` — the service doesn't know whether it talks to Postgres or an in-memory mock.

**Service layer** (`service.w`) — The `UserService` orchestrates CRUD, caching, notifications, and audit logging. A manual builder demonstrates by-value `self` chaining (§9.5).

**Infrastructure** (`repo/postgres.w`, `cache/redis.w`, `notify/email.w`) — Concrete implementations. Each is swappable at construction time.

**HTTP layer** (`http.w`) — Maps endpoints to service calls with pattern-matched error routing.

**Entry point** (`main.w`) — Wires everything together with structured concurrency, graceful shutdown via `select await`, and a `load_config_from_file` helper showing `.context()` error wrapping.

**Tests** (`tests.w`) — In-memory mocks for all four traits. Seven test functions covering CRUD, caching, batch ops, optional chaining, and enum accessors.

---

## Design Highlights

### Object-safe CacheService (byte-level trait + generic free functions)

Generic methods (`get[T: Deserialize]`) can't go in trait objects because each `T` would need its own vtable slot. The solution in `traits.w`: the trait defines `get_bytes`/`set_bytes` operating on `Vec[u8]`, and free functions `cache_get[T]`/`cache_set[T]` handle serialization outside the trait. This keeps `CacheService` object-safe while callers still get type-safe generics.

### Cache-through with structured concurrency

`get_profile` in `service.w` demonstrates the pattern: check cache, on miss fetch from repo, then fire three parallel enrichment queries (`count_posts`, `count_followers`, `last_login`) inside an `async scope`. The scope ensures all child tasks complete (or are cancelled) before the function returns. The result is written through to cache on the way out.

### Builder pattern with by-value self chaining

`UserServiceBuilder` in `service.w` uses `{ self with field: value }` record update syntax. Each setter consumes `self` by value and returns the updated builder, enabling `.repo(...).cache(...).notifier(...).build()` chaining without naming intermediate types.

### Graceful shutdown

`main.w` uses `async scope` + `select await` to race connection acceptance against a shutdown signal. When SIGTERM arrives, the accept loop breaks, and the scope cancels all child fibers. Cancellation triggers unwinding — every `with`-block guard is released, every resource cleaned up by destructors. No `finally`, no `defer`, no explicit cleanup code. See the cancellation flow diagram in `examples/service/README.md`.

### Error hierarchy and `error...from`

`errors.w` declares `error ServiceError from DbError, CacheError, NotifyError =` followed by the service's own variants (`Validation`, `TimedOut`, `Cancelled`) — the `from` list generates wrapper variants (`Db`, `Cache`, `Notify`) and `From` conversions, so `?` propagation works across subsystem boundaries, while the written variants are errors the service raises itself (§10.9, D57).

### `.context()` error wrapping

`load_config_from_file` in `main.w` demonstrates `.context()` and `.with_context()` (§10.6): wrapping low-level `IoError` values with human-readable messages, producing `ContextError[E]` that preserves the original error as `.source`.

```with
let text = std.fs.read_to_string(path)
    .context("reading config from {path}")?
toml.parse[ServiceConfig](&text)
    .with_context(|| "parsing config file {path}")?
```

### Derive annotations and default field values

`domain.w` uses `@[derive(Clone)]` on `User` and `CreateUserRequest`, and `@[derive(all)]` on `Role` and `Priority` enums. `UserUpdate` declares all fields with `= None` defaults, so partial updates are concise:

```with
svc.update_user(user.id, UserUpdate { name: Some("Robert") }, actor).await
```

### Optional chaining and enum accessors

`tests.w` exercises `?.` optional chaining (§10.3) through `Option` values and `??` for defaults. Enum accessor methods (`.is_admin()`, `.as_validation_ref()`) are auto-generated for every variant (§4.4).

---

## Feature Inventory

This example exercises the following spec features:

| Feature | Spec | Where Used |
|---------|------|------------|
| Trait definitions with async methods | §11.5 | traits.w — all four service traits |
| Trait objects (`dyn Trait`) | §11.3 | service.w — `Box[dyn UserRepository]`, etc. |
| `with` type-inferred guards | §7.1 | service.w, tests.w — lock access |
| `with` builder pattern | §7.2 | notify/email.w — SmtpMessage; service.w — Vec |
| `with` scoped binding | §7.3 | service.w — `describe_changes` |
| `with` record update | §7.4 | service.w — builder setters, partial user updates |
| `@[no_await_guard]` rule | §7.9 | Locks use `with` without `.await`; pools use `with` with `.await` |
| `@[derive(Clone)]` | §11.8 | domain.w — User, CreateUserRequest |
| `@[derive(all)]` | §11.8 | domain.w — Role, Priority |
| Default field values | §4.3 | domain.w (UserUpdate), service.w (ServiceConfig, ServiceMetrics) |
| `?` error propagation | §10.2 | Throughout |
| `?.` optional chaining | §10.3 | tests.w — `profile.last_login?.elapsed()` |
| `??` default operator | §10.4 | http.w — query params; tests.w — `?. ... ?? 0` |
| `.context()` / `.with_context()` | §10.6 | main.w — `load_config_from_file` |
| Implicit Ok wrapping | §4.9 | Throughout — happy-path returns unwrapped |
| `error...from` shorthand | §10.9 | errors.w — `ServiceError from DbError, CacheError, NotifyError` |
| `error` declarations | §10.8 | errors.w — all error types |
| `let...else` | §9.7 | service.w — `update_user` refutable pattern |
| Enum variant shorthand `.Variant` | §4.4 | Throughout — `.Admin`, `.Normal`, `.SIGTERM` |
| Enum accessor methods | §4.4 | tests.w — `.is_admin()`, `.as_validation_ref()` |
| Cancellation just works | §14.7 | No `Cancelled` variant needed |
| Structured concurrency (`s.track`) | §14.9 | main.w, service.w — `async scope` |
| `async:` blocks | §14.6 | Background health check (doc's main variant) |
| `select await` | §14.10 | main.w — shutdown, with_timeout |
| `task.cancel()` cooperative cancellation | §14.7 | main.w — with_timeout |
| `async fn` returns `Task[T]` | §14.4 | Throughout |
| Pipeline operator `\|>` | §9.6 | service.w — batch fetch, collection ops |
| By-value `self` method chaining | §9.5 | service.w — builder; main.w — builder |
| Pattern matching | §9.7 | http.w — error routing |
| Distinct types | §4.5 | domain.w — `type UserId = distinct i64` |
| Enum variants | §4.4 | domain.w — Role, Priority; errors.w |
| `str` as owned string type | §15.1 | Throughout |
| `.len32()` bounds-checked narrowing | §18.6 | tests.w — `sent.len32()` |
| `RwLock` as `Scoped`/`ScopedMut` | §18.6 | service.w — metrics; tests.w — mocks |
| Immutable by default | §2 | `let` everywhere, `var` only where needed |
| `@[must_use]` on Result/Task | §20b.2, §14.7 | Results handled via `?`/`match` |
| `sequence` / `traverse` | §10.7 | service.w — batch profile fetch |
| `.unwrap()` / `.expect()` | §10.6 | tests.w — test assertions |
| `unreachable()` | §18.6 | tests.w — unexpected match arms |
| `assert_matches` | §18.6 | tests.w — pattern matching on results |
| Unit elision | §4.8 | `Ok()` instead of `Ok(())` |
| Postfix `.await` | §14.5 | Throughout |
| Implicit builder return | §7.2 | `with ... as mut` blocks auto-return |
| Signal handling | §18.6 | main.w — `std.signal.wait(Signal.SIGTERM)` |
| String interpolation | §15 | Throughout |

---

For file descriptions, `with` usage census, and the cancellation flow diagram, see [`examples/service/README.md`](../examples/service/README.md).
