//! expect-check-fail: 'ok DB_OK' names a status, but no producer returns one to compare it with: 'db_make' returns nothing

// D51 stage 5, spec §16.2b.4: a void out-parameter producer has production
// (the slot) and no status, so `ok` has nothing to read.

use c_import("typedef struct db db;
#define DB_OK 0
void db_make(db** out);
void db_close(db* d);
")

c facade dbl:
    resource Database wraps *mut db
        from db_make(out param 0)
        drop db_close
        ok DB_OK

fn main:
    print("ok")
