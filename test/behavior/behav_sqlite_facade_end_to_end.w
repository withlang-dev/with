//! expect-stdout: version: 3
//! expect-stdout: exec: 0
//! expect-stdout: row: tag=2 cols=2
//! expect-stdout: exec aborted by the callback: true
//! expect-stdout: prepared: cols=2
//! expect-stdout: row 1: 42 hi bytes=2 name=s
//! expect-stdout: row 2: 7 NULL
//! expect-stdout: done: true changes=2
//! expect-stdout: prepare failed: 1 near "SELEKT": syntax error
//! expect-stdout: function registered: 0
//! expect-stdout: shout called
//! expect-stdout: shout() is NULL: true
//! expect-stdout: failed open: cantopen=true handle produced
//! expect-stdout: application data 1 destroyed
//! expect-stdout: close_v2: 0
//! expect-stdout: ok

// D51 stage 12 (ruling §66): the SQLite facade (lib/facades/sqlite3.w),
// against the real library, end to end — every item of §66 in one program
// that an application would write: no `unsafe`, no raw pointer. Open
// (out-parameter production, `ok SQLITE_OK`), exec with a callback and
// typed userdata (the callback aborts the query by returning non-zero, the
// witness that C ran it with the userdata it was given), prepare (the
// renamed method), step, column_int, column_text as Option[CStr] — Some
// for text, None for SQL NULL — with column_bytes and column_name
// preserving the view, errmsg on a failed prepare, create_function_v2
// consuming application data that C destroys through xDestroy once, when
// the connection closes (the Drop line lands before the close line), a
// failed open that still produced a handle (`FailedWithResource`, closed
// when the error is dropped), and close_v2 as the explicit destroyer.
use facades.sqlite3
use c_import("sqlite3.h", link: "sqlite3")

type Ctx { tag: i32 }
fn on_row(c: &Ctx, n: c_int, values: *mut *mut i8, names: *mut *mut i8) -> c_int:
    print(f"row: tag={c.tag} cols={n}")
    if c.tag == 2: 1 else: 0

type AppData { id: i32, name: str }
impl Drop for AppData:
    move fn drop(): print(f"application data {self.id} destroyed")

// The SQL function `shout()`: a retained callback (a code pointer; its
// application data would be reached through sqlite3_user_data). It sets
// no result, so the function yields SQL NULL.
fn shout(ctx: *mut sqlite3_context, n: c_int, argv: *mut *mut sqlite3_value):
    print("shout called")

fn main:
    print(f"version: {sqlite3_libversion().unwrap().to_str().unwrap().slice(0, 1)}")
    var db = Database.open(":memory:").unwrap()
    let rc = db.exec("CREATE TABLE t(v INTEGER, s TEXT); INSERT INTO t VALUES (42, 'hi'), (7, NULL);", on_row, Ctx { tag: 1 }, null)
    print(f"exec: {rc}")
    let aborted = db.exec("SELECT v, s FROM t", on_row, Ctx { tag: 2 }, null)
    print(f"exec aborted by the callback: {aborted == SQLITE_ABORT}")

    let stmt = db.prepare("SELECT v, s FROM t ORDER BY v DESC", -1, null).unwrap()
    print(f"prepared: cols={stmt.column_count()}")
    assert(stmt.step() == SQLITE_ROW)
    // The int first: `column_int` states no preservation (a column accessor
    // of another type may convert in place), so a text view taken before it
    // would be refused at its use — err_sqlite_facade_column_text_after_step
    // pins the step case.
    let v = stmt.column_int(0)
    let text = stmt.column_text(1).unwrap()
    print(f"row 1: {v} {text.to_str().unwrap()} bytes={stmt.column_bytes(1)} name={stmt.column_name(1).unwrap().to_str().unwrap()}")
    assert(stmt.step() == SQLITE_ROW)
    let v2 = stmt.column_int(0)
    let second = stmt.column_text(1)
    print(f"row 2: {v2} {if second.is_none(): "NULL" else: "text"}")
    print(f"done: {stmt.step() == SQLITE_DONE} changes={db.changes()}")

    match db.prepare("SELEKT", -1, null):
        Err(StatementError.Failed(status)) => print(f"prepare failed: {status} {db.errmsg().unwrap().to_str().unwrap()}")
        _ => print("unexpected")

    // A bare fn does not yet coerce to `extern "C" fn` through a generic
    // method's parameter (#1609): the retained callback is named through a
    // typed local. xStep and xFinal are not given (a scalar function).
    let x_func: extern "C" fn(*mut sqlite3_context, c_int, *mut *mut sqlite3_value) -> Unit = shout
    let registered = db.create_function_v2("shout", 0, SQLITE_UTF8, AppData { id: 1, name: "shout" }, x_func, null, null)
    print(f"function registered: {registered}")
    let call = db.prepare("SELECT shout()", -1, null).unwrap()
    assert(call.step() == SQLITE_ROW)
    print(f"shout() is NULL: {call.column_text(0).is_none()}")
    drop(call)
    drop(stmt)

    match Database.open("/nonexistent-with-dir/x.db"):
        Err(DatabaseError.FailedWithResource(status, failed)) => print(f"failed open: cantopen={status == SQLITE_CANTOPEN} handle produced")
        Err(e) => print(f"failed open: {e:?}")
        Ok(_) => print("unexpected")

    let closed = db.close_v2()
    print(f"close_v2: {closed}")
    print("ok")
