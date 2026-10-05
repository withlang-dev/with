//! skip-on: windows no host sqlite3 on Windows: this c_imports the host library's header (Linux CI installs it); the release UAT project gets it from `with get`
//! expect-stdout: sum 42
//! expect-stdout: exec: error=true message=near "SELEC": syntax error
//! expect-stdout: prepare: error=true message=no such table: nowhere
//! expect-stdout: open: cantopen=true
//! expect-stdout: ok

// #2179 (D97, spec §16.2b.4): `c facade sqlite error SqliteError` states one
// error type for every fallible operation of the facade. Opening, executing,
// preparing and stepping all return `Result[_, SqliteError]`, so a function
// that does all four needs no `error … from` declaration and no conversion;
// each failure keeps what the per-resource errors kept: an operation's
// status and the connection's message (`Failed`), a producer's message read
// through its parent, and the handle a failed open still produced, owned by
// the error as `FailedWithDatabase`.
use facades.sqlite3
use c_import("sqlite3.h", link: "sqlite3")

fn total(db: &Database) -> Result[i32, SqliteError]:
    db.exec("CREATE TABLE t(v INTEGER); INSERT INTO t VALUES (40), (2);")?
    let stmt = db.prepare("SELECT v FROM t")?
    var sum = 0
    while stmt.step()? == SQLITE_ROW: sum += stmt.column_int(0)
    sum

fn main:
    let Ok(db) = Database.open(":memory:") else:
        print("open failed")
        return 1
    match total(db):
        Ok(sum) => print(f"sum {sum}")
        Err(e) => print(f"failed: {e}")
    match db.exec("SELEC 1"):
        Err(SqliteError.Failed(status, message)) => print(f"exec: error={status == SQLITE_ERROR} message={message}")
        _ => print("exec: unexpected")
    match db.prepare("SELECT v FROM nowhere"):
        Err(SqliteError.Failed(status, message)) => print(f"prepare: error={status == SQLITE_ERROR} message={message}")
        _ => print("prepare: unexpected")
    match Database.open("/nonexistent-with-dir/x.db"):
        Err(SqliteError.FailedWithDatabase(status, _)) => print(f"open: cantopen={status == SQLITE_CANTOPEN}")
        _ => print("open: unexpected")
    print("ok")
