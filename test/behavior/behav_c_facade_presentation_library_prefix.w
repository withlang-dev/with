//! expect-stdout: step 105 column 12
//! expect-stdout: lib_reset 1 lib_stmt_reset 2
//! expect-stdout: ok

// D51 stage 12b (#1610; ruling §54, spec §16.2b.11): a C library names its
// types and its functions under one prefix, and an operation of a resource
// carries the library's prefix, not the struct's. `Statement wraps *mut
// lib_stmt` shortens by `lib_stmt_` and by the library prefix `lib_`, so
// `lib_step(lib_stmt *)` is `s.step()` and `lib_column` is `s.column(i)` —
// SQLite's `sqlite3_step(sqlite3_stmt *)` with no `rename`; `Database
// wraps *mut lib_db` likewise makes `lib_prepare(lib_db *)` `d.prepare(…)`
// beside `Statement.prepare(d, …)`. The longest matching prefix wins
// (`lib_stmt_bind` would be `bind`, not `stmt_bind`), and a clash still
// fails closed (§55): `lib_reset` and `lib_stmt_reset` both shorten to
// `reset`, so both keep their imported names, and the compiler never
// picks. A struct name with no library prefix is shortened as before.

use c_import("#include <stdlib.h>
typedef struct lib_db { int n; } lib_db;
typedef struct lib_stmt { lib_db *owner; int id; } lib_stmt;
static inline lib_db *lib_db_new(int n) { lib_db *d = (lib_db *)malloc(sizeof(lib_db)); d->n = n; return d; }
static inline void lib_db_close(lib_db *d) { free(d); }
static inline lib_stmt *lib_prepare(lib_db *d, int id) { lib_stmt *s = (lib_stmt *)malloc(sizeof(lib_stmt)); s->owner = d; s->id = id; return s; }
static inline void lib_finalize(lib_stmt *s) { free(s); }
static inline int lib_step(lib_stmt *s) { return s->owner->n * 100 + s->id; }
static inline int lib_column(lib_stmt *s, int i) { return s->id + i; }
static inline int lib_reset(lib_stmt *s) { return 1; }
static inline int lib_stmt_reset(lib_stmt *s) { return 2; }
")

c facade libp:
    resource Database wraps *mut lib_db
        from lib_db_new
        drop lib_db_close
    resource Statement wraps *mut lib_stmt
        from lib_prepare
        drop lib_finalize
    fn lib_step
        lend
    fn lib_column
        lend
    fn lib_reset
        lend
    fn lib_stmt_reset
        lend

fn main:
    let d = Database.new(1).unwrap()
    let s = d.prepare(5).unwrap()
    print(f"step {s.step()} column {s.column(7)}")
    print(f"lib_reset {s.lib_reset()} lib_stmt_reset {s.lib_stmt_reset()}")
    drop(s)
    print("ok")
