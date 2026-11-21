//! expect-stdout: 1
//! expect-stdout: 7

// D215: the raw function of a shared name is `c.name` inside `unsafe`, and
// each resource keeps its own constructor and method.
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
    let raw = unsafe { c.db_new(1) }
    print(unsafe { (*raw).id })
    let a = Database.new(2).unwrap()
    print(a.close_how(7))
