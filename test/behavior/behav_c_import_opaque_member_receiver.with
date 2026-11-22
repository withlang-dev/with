//! expect-stdout: ok
// c_import turns `db_close(db *)` into `impl db: mut fn close()` on the
// opaque `db`. windows-x86_64 sized every aggregate parameter to pick its
// pass mode, the `mut self` place included, and an opaque type has no size:
// "BUG: layout requested for a type holding 'db' by value before 'db' has a
// body (#1430)". A place passes its address whatever its type; it is never
// sized.

use c_import("typedef struct db db;
static inline db *db_new(int n) { (void)n; return (db *)0; }
static inline void db_close(db *d) { (void)d; }
")

fn main:
    let d = unsafe { db_new(1) }
    unsafe { db_close(d) }
    print("ok")
