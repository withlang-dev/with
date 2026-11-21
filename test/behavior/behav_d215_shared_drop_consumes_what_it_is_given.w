//! expect-stdout: 1
//! expect-stdout: 0
//! expect-stdout: 1

// D215 (§16.2b.11): a function that more than one resource names as its
// drop consumes whichever of those resources it is given. `db_close` is
// the drop of `Database` and of `Shared`; each call ends its own resource
// once, and the other is untouched.
use c_import("typedef struct db { int id; int closed; } db;
static db a_db; static db b_db;
static inline db* db_new(int id) { a_db.id = id; a_db.closed = 0; return &a_db; }
static inline db* db_open(int id) { b_db.id = id; b_db.closed = 0; return &b_db; }
static inline void db_close(db* d) { d->closed++; }
static inline int db_closed_a(void) { return a_db.closed; }
static inline int db_closed_b(void) { return b_db.closed; }
")

c contract dbs:
    resource Database wraps *mut db
        from db_new
        drop db_close
    resource Shared wraps *mut db
        from db_open
        drop db_close

fn main:
    let a = Database.new(1).unwrap()
    let b = Shared.open(2).unwrap()
    db_close(a)
    print(db_closed_a())
    print(db_closed_b())
    db_close(b)
    print(db_closed_b())
