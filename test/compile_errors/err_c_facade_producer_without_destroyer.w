//! expect-check-fail: producer 'db_new' with no 'drop' and no 'destroys'

// D51 §16.2b.3 / ruling §9 (never half-model unsafely): a resource with a
// producer and no destruction contract would be a safe constructor for a
// value nothing can release. It is a compile error at the resource.

use c_import("typedef struct db db;
db* db_new(int flags);
void db_close(db* d);
")

c facade dbl:
    resource Database wraps *mut db
        from db_new

fn main:
    print("ok")
