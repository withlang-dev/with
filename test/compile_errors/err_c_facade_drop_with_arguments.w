//! expect-check-fail: 'drop db_close_how' takes 2 parameters; the drop operation takes only the representation

// D51 §16.2b.3 stage 4a: Drop can pass nothing but the representation, so a
// `drop` operation with further parameters is rejected at the resource; an
// operation that needs arguments is a `destroys` (a `move fn` method).

use c_import("typedef struct db db;
db* db_new(int flags);
void db_close_how(db* d, int how);
")

c facade dbl:
    resource Database wraps *mut db
        from db_new
        drop db_close_how

fn main:
    print("ok")
