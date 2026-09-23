//! expect-check-fail: 'ok DB_OK' names a status, but 'Database' has no producer to read one from

// D51 stage 5, spec §16.2b.4: `ok` is a producer's success condition; a
// resource with no producer and no initializer has no status to read.

use c_import("typedef struct db db;
#define DB_OK 0
void db_close(db* d);
")

c facade dbl:
    resource Database wraps *mut db
        drop db_close
        ok DB_OK

fn main:
    print("ok")
