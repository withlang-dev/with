# C interop

Two C libraries used from With: one the system provides (SQLite) and one
vendored as source (`vendor/tally.c`). `src/main.w` uses both and contains no
`unsafe`.

```
with run        # builds vendor/tally.c, then the program
with build :test
```

## What each file shows

**`src/database.w` — importing a library, and owning what it hands out**

- `use c_import("sqlite3.h", link: "sqlite3")` brings in SQLite's functions,
  its opaque handle types (`*mut sqlite3`) and its `#define` constants
  (`SQLITE_OK`, `SQLITE_ROW`, `SQLITE_TRANSIENT`). Nothing is declared by hand.
- A `str` is passed where C wants `const char *`. With lends it for the call.
- Out-parameters: `var handle: *mut sqlite3 = null`, then `&raw mut handle`.
- `Database` and `Statement` own their handles. `impl Drop` closes and
  finalizes them on every path, including the ones `?` takes.
- A C error code becomes a With error carrying SQLite's message:
  `CStr.from_ptr(sqlite3_errmsg(db)).to_str()` copies the C string.
- A NULL column is `None`, not `""`: `text.as_option().map(...)`.
- Every `unsafe` block is one C call. Everything `pub` is safe.

**`src/tally.w` and `vendor/tally.{h,c}` — a vendored library, both directions**

- `build.w` compiles `vendor/tally.c` and archives it. The With compiler
  compiles the C; there is no Makefile and no C toolchain to install.
- A string macro is a `str` constant (`TALLY_VERSION`).
- `TallyRange` is passed to C and returned from C by value, with no
  declaration on the With side and no `unsafe`.
- `tally_calls`, a C global, is read like any other binding.
- A With function is a C callback. `collect` is an ordinary function handed to
  `tally_each`; its state travels through the `void *` the library hands
  back, because a C function pointer has nowhere to keep a closure's captures.
- `@[c_export("c_interop_score")]` gives a With function a C name and the C
  ABI. `tally.c` calls it without knowing it is With. For a C project,
  `with emit-c-header src/tally.w` writes the prototype.
- A slice reaches C as a pointer and a count; an empty one as `null` and `0`.

**`test/`** runs the real modules: rows and their order, NULL as `None`, a
bound runtime string, a C error as a With error, a failed open that still
closes, a struct by value both ways, the callback, the exported function, the
empty slice, the C global.

## Not here yet

- `with migrate` (C source to With). `std.build` has no migrate step for a
  project, so it cannot yet be part of `with build` here.
- Hand-written `extern "C"` declarations and `@[repr(C)]` types, for a
  library with no header.
