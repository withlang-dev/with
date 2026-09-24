//! expect-stdout: opened count 3 message fine
//! expect-stdout: failed status 1 message negative
//! expect-stdout: ok

// D51 stage 12b (#1612; ruling §18, spec §16.2b.4): the resource a failed
// producer still produced — `FailedWithResource`'s `FailedDatabase` —
// admits only the operations the facade marks `valid on failed`. Here
// `db_errmsg` is (the C library documents it on a failed open, as SQLite
// does sqlite3_errmsg), so `failed.errmsg()` is the same text view on the
// failed state, a view of it; `db_count` is not, and is not a method of
// the failed one (err_c_facade_failed_state_unmarked_item). The failed
// handle is still closed once, by the error's Drop.

use c_import("#include <stdlib.h>
#define DB_OK 0
typedef struct db { int n; } db;
static inline int db_open(int n, db **out) { db *d = (db *)malloc(sizeof(db)); d->n = n; *out = d; return n < 0 ? 1 : DB_OK; }
static inline void db_close(db *d) { free(d); }
static inline int db_count(db *d) { return d->n; }
static inline const char *db_errmsg(db *d) { return d->n < 0 ? \"negative\" : \"fine\"; }
")

c facade dbv:
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
    match Database.open(3):
        Ok(d) => print(f"opened count {d.count()} message {d.errmsg().unwrap().to_str().unwrap()}")
        Err(_) => print("unexpected")
    match Database.open(-1):
        Err(DatabaseError.FailedWithResource(status, failed)) => print(f"failed status {status} message {failed.errmsg().unwrap().to_str().unwrap()}")
        _ => print("unexpected")
    print("ok")
