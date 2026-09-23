//! expect-check-fail: unknown method 'db_count' for type 'FailedDatabase': a failed 'Database'

// D51 stage 5 (Eric, 2026-09-23, on #1426): the resource a failed producer
// still produced — `FailedWithResource`'s `FailedDatabase` — admits only the
// operations the facade states are valid on the failure state. A facade has
// no clause for that yet, so it admits none: `db_count`, a lend method of a
// live `Database`, is not a method of the failed one. Raw access to its
// representation under the raw C rules compiles
// (da_c_facade_error_owns_resource.w).

use c_import("typedef struct db db;
#define DB_OK 0
int db_open(const char* path, db** out);
void db_close(db* d);
int db_count(db* d);
")

c facade dbl:
    resource Database wraps *mut db
        from db_open(out param 1)
        drop db_close
        ok DB_OK
    fn db_count
        lend

fn main:
    match Database.db_open("x.db"):
        Ok(db) => print(f"{db.db_count()}")
        Err(DatabaseError.FailedWithResource(_, failed)) => print(f"{failed.db_count()}")
        Err(_) => print("failed")
