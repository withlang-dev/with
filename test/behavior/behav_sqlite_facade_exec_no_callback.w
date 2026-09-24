//! expect-stdout: create: 0
//! expect-stdout: insert: 0 changes=2
//! expect-stdout: select without callback: 0
//! expect-stdout: ok

// D51 stage 12b (#1618; ruling §43, §66; spec §16.2b.8-9): sqlite3_exec
// with no callback, as every DDL and DML statement runs it. The header
// states no nullability and the facade does ("If the callback pointer to
// sqlite3_exec() is NULL, then no callback is ever invoked and result
// rows are ignored"), so `db.exec(sql, None, None, null)` is the call
// the release UAT makes as `sqlite3_exec(db, sql, null, null, null)` —
// with no `unsafe`, no raw pointer and no no-op callback: the absent
// callback takes its userdata with it. A SELECT with no callback
// succeeds and its rows are ignored, as documented.
use facades.sqlite3
use c_import("sqlite3.h", link: "sqlite3")

fn main:
    let db = Database.open(":memory:").unwrap()
    print(f"create: {db.exec("CREATE TABLE t(v INTEGER)", None, None, null)}")
    let rc = db.exec("INSERT INTO t VALUES (1), (2)", None, None, null)
    print(f"insert: {rc} changes={db.changes()}")
    print(f"select without callback: {db.exec("SELECT v FROM t", None, None, null)}")
    print("ok")
