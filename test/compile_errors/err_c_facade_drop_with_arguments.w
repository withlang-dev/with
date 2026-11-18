//! expect-check-fail: 'drop db_close_how' takes 2 parameters, and Drop has only the representation to pass: param 1: i32 how is neither fixed nor discarded
//! expect-check-fail: = help: under 'fn db_close_how' write 'param 1 fixed <literal>', or write 'destroys db_close_how' and name another function as 'drop'

// D51 §16.2b.3 stage 4a: Drop can pass nothing but the representation, so a
// `drop` operation with further parameters is rejected at the resource; an
// operation that needs arguments is a `destroys` (a `move fn` method).

use c_import("typedef struct db db;
db* db_new(int flags);
void db_close_how(db* d, int how);
")

c contract dbl:
    resource Database wraps *mut db
        from db_new
        drop db_close_how

fn main:
    print("ok")
