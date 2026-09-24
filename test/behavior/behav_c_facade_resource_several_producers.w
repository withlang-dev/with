//! expect-stdout: first 1
//! expect-stdout: second 1
//! expect-stdout: ok

// D51 §16.2b.4: a resource may have several producers over one destruction
// contract (libc's fopen, fdopen and tmpfile each produce the FILE that
// fclose destroys). Each `from` is its own safe constructor; Drop runs the
// one `drop` exactly once whichever produced the value. Each C object counts
// its own destructions and is the witness.

use c_import("void *malloc(unsigned long size);
typedef struct db { int id; int closed; } db;
static inline db* db_new(int id) { db* d = (db*)malloc(sizeof(db)); d->id = id; d->closed = 0; return d; }
static inline db* db_new_named(const char* name) { return db_new(7); }
static inline void db_close(db* d) { d->closed++; }
static inline int db_closed(db* d) { return d->closed; }
")

c facade dbl:
    resource Database wraps *mut db
        from db_new
        from db_new_named
        drop db_close

fn main:
    let a = Database.new(1).unwrap()
    let pa = a.repr
    drop(a)
    let b = Database.new_named("x").unwrap()
    let pb = b.repr
    drop(b)
    unsafe:
        print(f"first {db_closed(pa)}")
        print(f"second {db_closed(pb)}")
    print("ok")
