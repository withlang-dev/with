//! skip-on: windows no host sqlite3 on Windows: this c_imports the host library's header (Linux CI installs it); the release UAT project gets it from `with get`
//! expect-stdout: create: true
//! expect-stdout: insert: true changes=2
//! expect-stdout: select without callback: true
//! expect-stdout: refused: 1 near "SELEC": syntax error
//! expect-stdout: ok

// D92 (ruling Amendment 3; spec §16.2b.4, §16.2b.11; #1618): sqlite3_exec
// with no callback, as every DDL and DML statement runs it. The facade
// presents the function twice; `exec` fixes the callback and its userdata
// to NULL ("If the callback pointer to sqlite3_exec() is NULL, then no
// callback is ever invoked and result rows are ignored"), so the call is
// `db.exec(sql)`, and `ok SQLITE_OK` makes it a `Result` whose error
// carries the connection's message. A SELECT with no callback succeeds
// and its rows are ignored, as documented.
use facades.sqlite3
use c_import("sqlite3.h", link: "sqlite3")

fn main:
    let db = Database.open(":memory:").unwrap()
    print(f"create: {db.exec("CREATE TABLE t(v INTEGER)").is_ok()}")
    let inserted = db.exec("INSERT INTO t VALUES (1), (2)")
    print(f"insert: {inserted.is_ok()} changes={db.changes()}")
    print(f"select without callback: {db.exec("SELECT v FROM t").is_ok()}")
    match db.exec("SELEC 1"):
        Err(SqliteError.Failed(status, message)) => print(f"refused: {status} {message}")
        Ok(_) => print("unexpected")
    print("ok")
