# Example: C Interop — SQLite Wrapper

Safe wrapper around the SQLite C library. Demonstrates how With's `c_import`
binds C headers automatically, how imported C functions are callable directly,
and how `unsafe`, `Drop`, and RAII keep pointer-heavy boundaries contained.

## Files

```
sqlite.w    Complete SQLite wrapper + demo
```

## What It Demonstrates

**Automatic C binding** — `use c_import("sqlite3.h", link: "sqlite3")` generates
With bindings from the C header. No hand-written declarations.

**RAII wrappers for C resources** — `Database` owns a `*mut sqlite3` handle and
closes it in `Drop`. `Statement` owns `*mut sqlite3_stmt` and finalizes it in `Drop`.
Resources are always cleaned up, even on error paths.

**Unsafe isolation** — Raw pointer operations are confined to small helper boundaries.
All public methods have safe signatures. Users of `Database` and `Statement` never
write `unsafe`.

**Generators for row iteration** — `gen fn rows(stmt: &Statement)` yields the
statement reference for each row, providing a natural `for row in rows(&query)`
loop over query results.

**Transactions with rollback** — `Database.transaction(body)` runs `BEGIN`,
executes the body, and `COMMIT`s on success or `ROLLBACK`s on error — without
masking the original error.

## Language Features

| Feature | Location |
|---------|----------|
| `c_import` directive | Top-level — binds `sqlite3.h` |
| `unsafe` blocks | Raw pointer boundaries (`str.from_c_str` helper) |
| `impl Drop` for RAII | `Database`, `Statement` — automatic cleanup |
| Error enums | `SqliteError` — 7 variants with context fields |
| `?` propagation | Throughout — `prepare()?`, `step()?`, `bind_text()?` |
| `.Variant` shorthand | Error construction — `.OpenFailed(...)`, `.BindFailed(...)` |
| Generators (`gen fn`) | `rows()` — lazy row iteration |
| Pipeline operators `\|>` | `ptr_to_string` — pointer conversion chain |
| `extend` blocks (§9.5) | `extend Database`, `extend Statement` — inherent methods |
| Implicit Ok wrapping (§4.9) | `open`, `execute`, `prepare`, `main` — no trailing `Ok(...)` |
| String interpolation | Error messages, demo output |
| `.len32()` | `bind_text` — string length as i32 |
| Implicit `for` iteration | `for (name, email, score) in users:` |
| Transactions / closures | `db.transaction(\|db\| ...)` — higher-order function with rollback |
