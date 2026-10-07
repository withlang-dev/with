# D97 — `TotalF64` is a numeric float key; `None` sorts first by declaration order; a facade may state one error type

**Laws:** 6, 1 (docs/mission.md).

**Date:** 2026-10-05. **Status:** ruled (Eric); spec v7.26. **Issues:** #2182,
#2179.

**Rulings.**
1. **`TotalF64` (#2182): a numeric key.** `std.TotalF64` (and `TotalF32`)
   wraps a float as a key: `==` is numeric except that every NaN equals every
   NaN and `-0.0` equals `0.0`; the order is the float order with NaN above
   every number. Rejected: IEEE 754 totalOrder (Rust's `total_cmp`), which
   makes `0.0` and `-0.0` two silent entries.
2. **`None` before `Some`.** Derived `Ord` orders an enum's variants by
   declaration, then their payloads, and that is the only rule. `Option` is
   declared `None | Some(T)` so that `None` sorts first. Rust and Haskell
   agree; no special case for `Option`.
3. **One error type per facade (#2179).** A facade header may state
   `error SqliteError`. Every producer and status operation with `ok` then
   returns `Result[_, SqliteError]`, with `Failed(status)` (plus `message`
   when the resource has one), a `FailedWith<R>` per producer that can fail
   with its resource, and `NothingProduced(status)`. Without the clause, the
   per-producer errors of §16.2b.4 stay. Eric approved the SQLite fixture's
   `-> Result[i32, SqliteError]` with no `from` line.

**Why.** The references:
- Swift and Go: `-0.0` keys equal `0.0`.
- `ordered_float`: NaN == NaN.
- Rust and Haskell: `None` first.
- rusqlite, `database/sql` and SQLite.swift: one error type per library.

Each choice is the common case done right. The facade clause was the one
that mattered: it is what every C library's users see.

**Reopen if** a numeric program needs `-0.0` and `0.0` as distinct keys: the
answer is a second wrapper that names totalOrder, not a change to this one.
