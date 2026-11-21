//! expect-stdout: 7
//! expect-stdout: 10

// D215 (§16.2b.11): a destroyer's C name consumes the resource, with the
// destroyer's other arguments; the resource's drop does not run again.
use c_import("typedef struct db { int id; int closed; } db;
static db a_db;
static inline db* db_new(int id) { a_db.id = id; a_db.closed = 0; return &a_db; }
static inline void db_close(db* d) { d->closed++; }
static inline int db_close_how(db* d, int how) { d->closed += 10; return how; }
static inline int db_closed(void) { return a_db.closed; }
")

c contract dbs:
    resource Database wraps *mut db
        from db_new
        drop db_close
        destroys db_close_how

fn main:
    let a = Database.new(1).unwrap()
    print(db_close_how(a, 7))
    print(db_closed())
