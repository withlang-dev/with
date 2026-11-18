# D215 — A described function's C name means the modeled operation

**Laws:** 4 (one name, one meaning), R4c (`unsafe` does not change what a
name resolves to, so the raw function needs a name of its own).

**Date:** 2026-11-18. **Status:** ruled by Eric. The spec words are derived
and come to him as a diff with the implementation.

**Context.** #3291: what a call by a described function's C name meant
depended on how the resource was represented. For a by-value resource whose
record holds a pointer (raylib's `Image`), `LoadImage(…)` was the modeled
operation, through a rendered forwarder. For a pointer resource
(`Database wraps *mut db`), `db_new(…)` was a raw call needing `unsafe`,
with an error naming the modeled spelling. One name, two meanings chosen by
representation: the worst of the options.

**Ruling.**

- **Uniform meaning.** A described function's C name is its modeled
  operation, for pointer and in-place resources as for by-value ones.
- **The change at existing call sites is never silent.** Every changed call
  is a type error: `unsafe { db_new(1) }` now returns an `Option[Database]`
  where the code expected a `*mut db`, so it fails to compile where the
  result is used. The affected sites are still counted before landing.
- **A producer with an out-parameter takes the modeled argument list.** The
  slot is what the contract removes. Someone typing `sqlite3_open(path,
  &db)` from the C documentation gets an arity error, and that error
  teaches: "the contract produces the `Database`; write `let db =
  sqlite3_open(path)?`."
- **A destroy by C name is the consuming call**, as `UnloadImage(image)`
  already is.
- **The raw declaration has one spelling of its own**, such as
  `c.sqlite3_open(...)`, which requires `unsafe`. A contract applies
  wherever its header is imported. The contract's own rendering and the
  hand-written layer under it use that spelling. One namespace, one
  sentence each in §31 and §16.2b.11.
- **A function used as a value** (`let f = db_new`) stays an error until
  someone needs it.

**Why not the module boundary for raw reach.** It brings back the defect
this ruling removes: `sqlite3_open` would mean the modeled operation in one
file and the raw function in the next, by whether the contract is visible.
It forces a file split for one raw call (the runtime keeps contracts and
raw libc calls in the same files). And R4c already points at the answer.
The count does not decide this: the argument is the principle, not the
frequency.

**Reopen if** the raw spelling's namespace collides with a program's own
names in a way a rename cannot settle.
