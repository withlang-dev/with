//! expect-check-fail: `db_close_how` is named by more than one resource, so the C name has no one modeled meaning (§16.2b.11)
//! expect-check-fail: = help: write `value.close_how(…)` on a `Database`, or `value.close_how(…)` on a `Shared`; the raw function is `unsafe { c.db_close_how(…) }`

// D215: a destroyer with further arguments that several resources name
// has no shared form yet; its bare C name is an error naming the methods.
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
    let a = Database.new(1).unwrap()
    print(db_close_how(a, 7))
