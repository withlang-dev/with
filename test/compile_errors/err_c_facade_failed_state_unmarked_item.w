//! expect-check-fail: unknown method 'count' for type 'FailedDatabase': a failed 'Database'

// D51 stage 12b (#1612; spec §16.2b.4): a failed-state resource admits
// only the operations its facade marks `valid on failed`. `db_errmsg` is
// marked and is a method of the failed one; `db_count`, a lend of a live
// `Database` the facade did not mark, is not — the conservative default
// (Eric, 2026-09-23, on #1426: "the failed-state resource admits raw
// access only, until the facade can mark operations valid on the failure
// state").

use c_import("typedef struct db db;
#define DB_OK 0
int db_open(const char* path, db** out);
void db_close(db* d);
int db_count(db* d);
const char *db_errmsg(db* d);
")

c facade dbl:
    resource Database wraps *mut db
        from db_open(out param 1)
        drop db_close
        ok DB_OK
    fn db_count
        lend
    fn db_errmsg
        returns borrow CStr from param 0
        valid on failed

fn main:
    match Database.open("x.db"):
        Ok(db) => print(f"{db.count()}")
        Err(DatabaseError.FailedWithResource(_, failed)) => print(f"{failed.errmsg().is_some()} {failed.count()}")
        Err(_) => print("failed")
