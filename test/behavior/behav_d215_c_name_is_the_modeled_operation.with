//! expect-stdout: 7
//! expect-stdout: 7
//! expect-stdout: 9
//! expect-stdout: closed

// D215 (§31, §16.2b.11): a described function's C name is its modeled
// operation for a pointer resource too: `db_new(7)` produces the
// `Database`, `db_flags(p)` is the lend, `db_close(p)` the consuming
// destroy. The raw declaration is spelled `c.name(…)` and needs `unsafe`.
use c_import("typedef struct db { int flags; } db;
static db the_db;
static inline db* db_new(int flags) { the_db.flags = flags; return &the_db; }
static inline int db_flags(db* d) { return d->flags; }
static inline void db_close(db* d) { d->flags = -1; }
")

c contract dbl:
    resource Database wraps *mut db
        from db_new
        drop db_close
    fn db_flags
        of Database
        lend

fn main:
    let p = db_new(7).unwrap()
    print(db_flags(p))
    print(p.flags())
    let raw = unsafe { c.db_new(9) }
    print(unsafe { c.db_flags(raw) })
    db_close(p)
    print("closed")
