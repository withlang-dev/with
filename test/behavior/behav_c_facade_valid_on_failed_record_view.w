//! expect-stdout: opened: code=0 line=1
//! expect-stdout: failed status 1: code=14 line=7
//! expect-stdout: ok

// Spec §16.2b.4 (D71, ruling Amendment 1, #1612): "An operation the C
// contract documents as valid on a failed resource is marked on its fn item
// with `valid on failed`, and is presented on the failed-state type as
// well." Every presented lend shape is an operation: here a borrowed record
// view (`returns borrow db_status from param 0`, D66), the status record the
// failed handle still carries, read through `FailedDatabase` as through
// `Database` — a view of the failed handle, which its error's Drop closes.

use c_import("#include <stdlib.h>
#define DB_OK 0
typedef struct db_status { int code; int line; } db_status;
typedef struct db { db_status last; } db;
static inline int db_open(int n, db **out) {
    db *d = (db *)malloc(sizeof(db));
    d->last.code = n < 0 ? 14 : 0; d->last.line = n < 0 ? 7 : 1;
    *out = d;
    return n < 0 ? 1 : DB_OK;
}
static inline void db_close(db *d) { free(d); }
static inline const db_status *db_last(db *d) { return &d->last; }
")

c facade dbs:
    resource Database wraps *mut db
        from db_open(out param 1)
        drop db_close
        ok DB_OK
    fn db_last
        returns borrow db_status from param 0
        valid on failed

fn main:
    match Database.open(3):
        Ok(d) => print(f"opened: code={d.last().unwrap().code} line={d.last().unwrap().line}")
        Err(_) => print("unexpected")
    match Database.open(-1):
        Err(DatabaseError.FailedWithResource(status, failed)) => print(f"failed status {status}: code={failed.last().unwrap().code} line={failed.last().unwrap().line}")
        _ => print("unexpected")
    print("ok")
