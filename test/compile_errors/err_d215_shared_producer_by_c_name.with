//! expect-check-fail: `db_new` is named by more than one resource, so the C name has no one modeled meaning (§16.2b.11)
//! expect-check-fail: = help: write `Database.new(…)`, or `Shared.new(…)`; the raw function is `unsafe { c.db_new(…) }`

// D215 (Eric, 2026-11-20): a producer several resources name has no
// resource argument to choose by, so its bare C name is an error, in safe
// code and inside `unsafe` alike; it names the constructors and the raw
// spelling.
use c_import("typedef struct db { int id; int closed; } db;
static db a_db;
static inline db* db_new(int id) { a_db.id = id; a_db.closed = 0; return &a_db; }
static inline void db_close(db* d) { d->closed++; }
static inline int db_close_how(db* d, int how) { d->closed += 10; return how; }
")

c contract dbs:
    resource Database wraps *mut db
        from db_new
        drop db_close
        destroys db_close_how
    resource Shared wraps *mut db
        from db_new
        drop db_close
        destroys db_close_how

fn main:
    let p = unsafe { db_new(1) }
    print(1)
