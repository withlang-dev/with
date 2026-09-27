//! expect-stdout: temporary 108
//! expect-stdout: dropped 7
//! expect-stdout: place 111
//! expect-stdout: place again 112
//! expect-stdout: none -1
//! expect-stdout: ok
//! expect-stdout: dropped 11

// #1765 (§4 variant shorthand, §16.2b.9): a nullable callback's userdata
// parameter is `Option[&U]`, so `.Some(x)` is `Some(x)` there — a temporary
// payload is borrowed for the call and dropped at the end of the statement,
// a place stays usable afterwards — and `.None` is `None`. Sema checked the
// userdata with no expected type (its `U` comes from the payload), and the
// shorthand needs its enum: "cannot infer the enum type for `.Some`".
use c_import("#include <stdlib.h>
typedef int (*db_cb)(void *ud, int n);
typedef struct db { int total; } db;
static inline db *db_new(int n) { db *d = (db *)malloc(sizeof(db)); d->total = n; return d; }
static inline void db_close(db *d) { free(d); }
static inline int db_exec(db *d, db_cb cb, void *ud, int n) { if (!cb) return ud ? -2 : -1; int r = cb(ud, n); d->total += r; return r; }
")

c facade dbt:
    resource Database wraps *mut db
        from db_new
        drop db_close
    fn db_exec
        callback param 1 userdata param 2
        nullable param 1

type Ctx { base: i32, label: str }
impl Drop for Ctx:
    move fn drop(): print(f"dropped {self.base}")

fn on(c: &Ctx, n: c_int) -> c_int: c.base + n + c.label.len() as i32 - 1

fn main:
    let d = Database.new(0).unwrap()
    print(f"temporary {d.exec(Some(on), .Some(Ctx { base: 7, label: "x".clone() }), 101)}")
    let ctx = Ctx { base: 11, label: "z".clone() }
    print(f"place {d.exec(Some(on), .Some(ctx), 100)}")
    print(f"place again {d.exec(Some(on), .Some(ctx), 101)}")
    print(f"none {d.exec(None, .None, 100)}")
    print("ok")
