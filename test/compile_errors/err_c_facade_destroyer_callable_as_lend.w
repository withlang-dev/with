//! expect-check-fail: 'db_close' destroys the resource but the fn item describing it lends its parameters

// D51 §16.2b.3 / ruling §9 (never half-model unsafely): a destroying
// operation must not also be callable as a lend. The resource names db_close
// as its `drop`; an fn item says the same function lends. Compile error.

use c_import("typedef struct db db;
db* db_new(int flags);
void db_close(db* d);
")

c facade dbl:
    resource Database wraps *mut db
        from db_new
        drop db_close
    fn db_close
        lend

fn main:
    print("ok")
