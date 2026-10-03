//! expect-contract: violations=0 ok
//! expect-contract-not: holds no modeled resource

// #1834 (ruling Amendment 1, spec §16.2b.4): an operation marked `valid on
// failed` is "presented on the failed-state type as well" — `errmsg()` on
// the `FailedDatabase` a failed `open` still produced, "a resource owned
// by an error … carried as a distinct type". It states no `preserves`, so
// by §38 the rendered `FailedDatabase.errmsg` invalidates views of its
// receiver, and that receiver holds the modeled resource: the audit read
// `FailedDatabase` as holding nothing and reported the effect as naming
// the wrong parameter (#1674's class) over every program using the SQLite
// facade. contract-view-tests runs audit:all over this fixture, so the
// failed-state rendering is now in the battery.
use c_import("typedef struct sqlite3 sqlite3;
#define SQLITE_OK 0
int sqlite3_open(const char *filename, sqlite3 **ppDb);
int sqlite3_close(sqlite3 *db);
const char *sqlite3_errmsg(sqlite3 *db);
")

c facade sqlite:
    resource Database wraps *mut sqlite3
        from sqlite3_open(out param ppDb)
        drop sqlite3_close
        ok SQLITE_OK
    fn sqlite3_errmsg
        returns borrow CStr from param 0
        valid on failed

fn main:
    match Database.open("/nonexistent-with-dir/x.db"):
        Err(DatabaseError.FailedWithResource(status, failed)) => print(f"failed open: {status} {failed.errmsg().is_some()}")
        Err(e) => print(f"failed open: {e:?}")
        Ok(db) => print(f"open: {db.errmsg().is_some()}")
