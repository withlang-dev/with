//! expect-check-fail: 'ok DB_OK' names a status, but no producer returns one to compare it with: 'db_new' returns the resource itself

// D51 stage 5, ruling §17/§19, spec §16.2b.4: `ok` interprets a producer's
// status. A direct-return producer returns the resource itself — its
// failure is NULL, `Option[R]` with no `ok` clause — so the clause has
// nothing to read.

use c_import("typedef struct db db;
#define DB_OK 0
db* db_new(int flags);
void db_close(db* d);
")

c facade dbl:
    resource Database wraps *mut db
        from db_new
        drop db_close
        ok DB_OK

fn main:
    print("ok")
