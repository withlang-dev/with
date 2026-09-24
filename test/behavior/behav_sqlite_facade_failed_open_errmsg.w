//! expect-stdout: failed open: cantopen=true message=unable to open database file
//! expect-stdout: ok

// D51 stage 12b (#1612; ruling §18, spec §16.2b.4): "A resource owned by an
// error admits raw access only, unless the facade marks an operation as
// valid on the failure state." SQLite documents exactly one such operation
// on a failed open: "The sqlite3_errmsg() or sqlite3_errmsg16() routines
// can be used to obtain an English language description of the error
// following a failure of any of the sqlite3_open() routines." The facade
// states `valid on failed` on sqlite3_errmsg, so the `FailedDatabase` an
// open that still produced a handle carries has `errmsg()` — the same
// text view, a view of the failed resource — and an application reads why
// the open failed with no `unsafe` and no raw pointer. The handle is still
// closed when the error is dropped (da_sqlite_facade_destroy_once).
use facades.sqlite3
use c_import("sqlite3.h", link: "sqlite3")

fn main:
    match Database.open("/nonexistent-with-dir/x.db"):
        Err(DatabaseError.FailedWithResource(status, failed)) => print(f"failed open: cantopen={status == SQLITE_CANTOPEN} message={failed.errmsg().unwrap().to_str().unwrap()}")
        Err(e) => print(f"failed open: {e:?}")
        Ok(_) => print("unexpected")
    print("ok")
