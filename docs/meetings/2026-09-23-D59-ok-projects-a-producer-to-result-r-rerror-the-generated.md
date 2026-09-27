# D59 — `ok` projects a producer to `Result[R, RError]`; the generated error owns a failed-but-produced resource

**Date:** 2026-09-23. **Status:** BDFL ruling (Eric: 1(a), 2(A), 3 yes,
4 yes, with the refinements below; spec wording "blessed"); §16.2b.4 carries
the blessed text. Ruling §15–§19 (D51) left the projection's surface open:
"A high-level `Result` API is therefore a projection over the lower-level
production model. A facade-specific error type may itself temporarily own
the failure-state resource where required."

**Decision.** A producer with `ok CONST` returns `Result[R, RError]`, `RError`
a generated `error` declaration with `Failed(status)`,
`FailedWithResource(status, resource: R)` and `NothingProduced(status)`.
In-place producers get the same projection without `FailedWithResource`.
The low-level `(status, Option[R])` constructor exists only without `ok`.

**Why.**
- **Success with nothing produced** (SQLite's `sqlite3_prepare_v2` on empty
  SQL) is a violated C contract, so it is an error. It gets its own variant:
  `Failed(status: SQLITE_OK)` reads as a contradiction in a log line.
  `Result[Option[R], E]` would tax every caller for a case most producers
  cannot hit.
- **An `error` declaration, not a struct and not a named clause**, because
  D57 already gives errors their composition (`error AppError from
  DatabaseError`), and a clause makes the author write what is derivable.
- **The first error type with a destructor.** `FailedWithResource` owns the
  handle (SQLite requires closing a failed open), so the error has Drop, and
  `?` moves that ownership up through frames, never copies it.
- **The failed-state resource admits raw access only**, until the facade can
  mark operations valid on the failure state: `sqlite3_errmsg` is,
  `sqlite3_exec` meaningfully is not. The conservative default can be
  widened later.
- **In-place with `ok`** applies §16.2b.3's own rule ("Drop is armed only
  when initialization establishes production") to the failed branch. It
  closes a real hole: the destroyer ran on storage `z_init` never
  initialized. With pinning (D54), the failed branch frees the heap cell
  with no destruction call: the one such case.
- **One call surface per production form.** Libraries whose success codes
  are several constants (`SQLITE_OK`, `SQLITE_ROW`, `SQLITE_DONE`) are an
  argument for letting `ok` take a list, not for keeping the raw form.
- **The generated name collides loudly.** A declared or imported type with
  the generated name is an error naming both, the type-level form of D57's
  variant-collision rule.

**What the others do.** Rust std's `cvt_nz` maps 0 to `Ok` and carries the
code, never a handle. Swift's `swift_error(null_result)` covers only NSError
out-parameters. Go returns both values. Zig's error unions carry no payload.
None lets a "failed but produced" error own the resource; that part is With's
own (ruling §18).

**Naming.** The constructor is rendered under the imported C name
(`Database.sqlite3_open`) until presentation (§16.2b.11, plan stage 8)
shortens it (`Database.open`). Examples quoting the C name are not the final
spelling.

**Amended 2026-09-23** (Eric: "blessed"), from implementing it (#1426):
- **The failed resource is a distinct type, `FailedDatabase`, with no
  presented methods.** With `resource: Database`, a `match` moved the handle
  out as an ordinary `Database` with every method, so "raw access only"
  could not be enforced. The distinct type still owns the handle and runs
  the facade's `drop` once.
- **An in-place `ok` error has only `Failed`.** A successful in-place
  initialization always produced the resource, so `NothingProduced` could
  never occur there and every caller would have had to match it.

**Reopens if** a facade needs operations on the failure-state resource
(the marking clause), or `ok` needs several success constants.

---
