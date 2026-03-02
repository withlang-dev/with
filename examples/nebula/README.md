# Nebula — Concurrent Telemetry Ingestion Daemon

A concurrent telemetry daemon designed as a stress test for the With compiler. Combines high-level async ergonomics with low-level C-interop, compile-time metaprogramming, and strict ownership rules.

## Files

```
nebula/
├── with.toml
├── README.md
├── src/
│   ├── main.w       Entry point: threads, fibers, channels, signals
│   ├── schema.w     Domain types, comptime metaprogramming, config
│   ├── db.w         SQLite via c_import, unsafe, RAII, Drop
│   └── session.w    Generators, SlotMap arenas, pipelines, select
└── test/
    └── nebula_test.w
```

## What It Demonstrates

### `schema.w` — Metaprogramming & Domain Types
- **comptime reflection**: `derive_sql_record[T]` inspects `T.fields()` at compile time to auto-generate `impl SqlRecord`
- **Collection comprehensions**: `[f.name for f in fields]` evaluated at compile time
- **Algebraic data types**: `Status = Ok | Warning(str) | Fatal(code: i32)`
- **Enum variant shorthand**: `.Ok`, `.Warning(...)` where type is known
- **Default field values**: `temp: f64 = 0.0`
- **Record update syntax**: `{ base with port }` — functional update
- **Field shorthand**: `{ port }` means `{ port: port }`
- **The `in` operator**: `sev in [.High, .Critical]` for set membership
- **`with ... as mut`**: Scoped mutation for building batches

### `db.w` — C-Interop, `unsafe`, & Resource Safety
- **`c_import`**: `use c_import("sqlite3.h", link: "sqlite3")` — automatic C bindings
- **`unsafe` blocks**: FFI calls to sqlite3_open, sqlite3_exec, etc.
- **`impl Drop`**: Deterministic cleanup — sqlite3_close on scope exit
- **`c"..."` string literals**: Zero-cost NUL-terminated C strings
- **Implicit `Ok(...)` wrapping**: Happy path returns the value; compiler wraps
- **Implicit `Ok(())`**: Functions returning `Result[Unit, E]` end without ceremony
- **`@[no_await_guard]`**: Mutex blocks reject `.await` at compile time
- **`defer`**: Guaranteed cleanup for prepared statements
- **Pipeline operators**: Error message construction

### `session.w` — Fibers, Arenas, Pipelines & Generators
- **`gen fn`**: `extract_packets` compiles to a state machine, yields lazily
- **Generator composition**: `sliding_window[T]` over generic slices
- **`SlotMap`**: Generational arena — handles detect use-after-remove
- **`select await biased`**: Priority-based multiplexing (IO before timeout)
- **`let ... else`**: `let Ok(n) = bytes_read else break` — flat early exit
- **Chained `if let`**: `if let Some(a) = ..., let Some(b) = ...:` — no pyramid
- **Pipeline operators**: `extract_packets(&buf) |> filter_map(...) |> collect[Vec]()`
- **`traverse`**: Map + collect-or-fail for batch parsing
- **`not in`**: `p.status not in [.Fatal(code: 1), .Fatal(code: 2)]`
- **`defer` with `with`**: Guaranteed arena cleanup across error paths
- **`??` default operator**: `temp_str.parse_f64() ?? 0.0`

### `main.w` — Structured Concurrency & Thread Boundaries
- **OS threads vs fibers**: `thread.spawn_os` for CPU work, `async` for I/O
- **Channels**: `chan[Unit](1)` — bounded channel for shutdown signaling
- **`on_signal`**: `on_signal(.SIGINT, || drop(shutdown_tx))` — graceful shutdown
- **`async scope`**: All tracked fibers complete before scope exits
- **`select await`**: Race new connections against shutdown signal
- **`error ... from`**: `AppError from IoError, DbError` — auto-generates From impls
- **`Arc`**: Thread-safe shared ownership of database handle
- **Postfix `.await`**: `server_task.await` blocks until complete

## Language Features

| Feature | Spec | Location |
|---------|------|----------|
| Algebraic data types | S4.3 | `schema.w` — Status, Severity |
| Default field values | S4.1 | `schema.w` — Telemetry, ServerConfig |
| @[derive] attributes | S10.1 | `schema.w` — Debug, Clone |
| comptime metaprogramming | S10.3 | `schema.w` — derive_sql_record |
| Collection comprehensions | S6.10 | `schema.w` — [f.name for f in fields] |
| Record update syntax | S4.1 | `schema.w` — { base with port } |
| Field shorthand | S4.1 | All files |
| Enum variant shorthand | S4.3 | All files — .Ok, .Warning(...) |
| The `in` operator | S6.12 | `schema.w`, `session.w` |
| c_import | S12.1 | `db.w` — sqlite3.h |
| unsafe blocks | S12.2 | `db.w` — FFI calls |
| impl Drop | S9.6 | `db.w` — Database cleanup |
| c"..." literals | S12.1 | `db.w` — NUL-terminated strings |
| Implicit Ok wrapping | S7.1 | `db.w` — happy path returns |
| @[no_await_guard] | S11.8 | `db.w` — Mutex in with-block |
| defer | S6.6 | `db.w`, `session.w` |
| gen fn (generators) | S8.4 | `session.w` — extract_packets, sliding_window |
| SlotMap arenas | S5.3 | `session.w` — SessionPool |
| select await biased | S11.5 | `session.w` — handle_client |
| let ... else | S6.3 | `session.w` — pattern early exit |
| Chained if let | S6.3 | `session.w` — parse_telemetry |
| Pipeline operators | S6.11 | `session.w` — filter_map \|> collect |
| traverse | S6.13 | `session.w` — parse_batch |
| ?? default operator | S7.2 | `session.w` — parse_f64() ?? 0.0 |
| with blocks | S6.7 | All files — scoped access |
| OS threads | S11.1 | `main.w` — thread.spawn_os |
| Channels | S11.3 | `main.w` — chan[Unit] |
| Signal handling | S11.7 | `main.w` — on_signal(.SIGINT) |
| async scope | S11.4 | `main.w` — structured concurrency |
| select await | S11.5 | `main.w` — accept vs shutdown |
| error ... from | S7.4 | `main.w` — AppError |
| Arc shared ownership | S5.2 | `main.w` — Arc[Database] |
| Trait definitions | S9.1 | `schema.w` — SqlRecord |
| Closures | S8.2 | `session.w` — filter_map, filter |
| String interpolation | S3.4 | All files — "text {expr}" |
