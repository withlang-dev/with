# C interop

Two C libraries used from With: one the system provides (SQLite) and one
vendored as source (`vendor/tally.c`). The application uses both without
`unsafe`. The C contracts live in *facades* (`src/facades/`), ordinary With
source that states what a header cannot: which call produces a resource,
which one gives it back, what a returned pointer borrows from.

```
with run          # builds vendor/tally.c, then the program
with build :test  # 12 tests over the real libraries
```

## What each file shows

**`src/facades/sqlite3.w` — the facade, and `src/main.w` — the program**

- `use c_import("sqlite3.h", link: "sqlite3")` brings in SQLite's functions,
  its handle types and its `#define` constants. The facade names the handle
  types by the spelling `c_import` gives them (`*mut sqlite3`) and says, per
  declaration, what the header could not: `resource Database wraps *mut sqlite3`,
  produced by `sqlite3_open` through its out-parameter, dropped by
  `sqlite3_close`, its status read against `SQLITE_OK`; a `Statement` that
  borrows its connection; `sqlite3_errmsg` as a view of the connection.
  Every clause quotes the SQLite sentence it relies on.
- From those facts the compiler renders the safe surface. `Database.open`
  returns `Result[Database, DatabaseError]`; `db.exec`, `db.prepare`,
  `stmt.step`, `stmt.bind_int`, `stmt.column_int`, `stmt.column_text` are
  the C functions, presented as methods. A `str` is passed where C wants
  `const char *`.
- Ownership without `Drop` impls: the connection is closed when `db` leaves
  its scope, on every path; the statement is finalized first, because it
  depends on the connection and the facade says so.
- A NULL column is `None`, not `""`: `column_text` returns `Option[&CStr]`, a
  view of the statement. Conversion to With text is explicit
  (`to_str_lossy()`), and a view taken before the next `step` is refused
  after it.
- A C error is With values: the status the call returned, and `db.errmsg()`,
  read before the next call replaces it.
- The facade is the project's own copy of the With repository's
  `lib/facades/sqlite3.w`, until the `c.sqlite3` package ships it.

**`src/facades/tally.w`, `src/tally.w` and `vendor/tally.{h,c}` — a vendored
library, both directions**

- `build.w` compiles `vendor/tally.c` and archives it. The With compiler
  compiles the C; there is no Makefile and no C toolchain to install.
- A string macro is a `str` constant (`TALLY_VERSION`); `tally_calls`, a C
  global, is read like any other binding.
- `TallyRange` is passed to C and returned from C by value, with no
  declaration on the With side. The facade records the call as a lend.
- A With function is a C callback. `collect` is an ordinary function handed
  to `tally_each`. Its typed userdata borrows a capturing With callable;
  invoking it pushes into the caller's vector safely. The facade pairs the
  callback and userdata, and the compiler handles C's `void *` transport.
- `@[c_export("c_interop_score")]` gives a With function a C name and the C
  ABI. `tally.c` calls it without knowing it is With. For a C project,
  `with emit-c-header src/tally.w` writes the prototype.
- `buffer param values len param count elements` presents a typed slice.
  The compiler supplies its pointer and checked element count; an empty
  slice reaches C as `null` and `0`.

**`test/`** runs the real modules: rows and their order, NULL as `None`, a
bound parameter, a C error as With values, a failed open whose message is
still readable (the handle SQLite produced is owned by the error and closed
with it), a struct by value both ways, the callback, the exported function,
the empty slice, the C global.

## Not here yet

- Binding text: `sqlite3_bind_text` takes a destructor argument whose safe
  value is the `SQLITE_TRANSIENT` sentinel, a fixed argument the facade
  should bind (`param 4 fixed SQLITE_TRANSIENT`, D64) and does not yet. The
  example binds an integer.
- `with migrate` (C source to With). `std.build` has no migrate step for a
  project, so it cannot yet be part of `with build` here.
- Hand-written `extern "C"` declarations and `@[repr(C)]` types, for a
  library with no header.
