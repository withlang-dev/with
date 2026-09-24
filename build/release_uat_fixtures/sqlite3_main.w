// Release UAT: SQLite through its facade (D51, ruling §66; spec §16.2b). The
// program an application developer writes over `with get c.sqlite3`: the
// facade `facades.sqlite3` is the project's own (§16.2b.1), and the raw
// import names the status constants. No `unsafe`, no raw pointer: the
// connection and the statement are owned resources, closed and finalized by
// their scopes on every path, the statement before the connection (§16.2b.6).
use facades.sqlite3
use c_import("sqlite3.h")

fn main:
    let Ok(db) = Database.open(":memory:") else:
        print("sqlite3 open failed")
        return 1
    // No row callback (#1618: `None` declines the callback and its userdata).
    if db.exec("CREATE TABLE t(value INTEGER); INSERT INTO t(value) VALUES (42);", None, None) != SQLITE_OK:
        print("sqlite3 exec failed")
        return 1
    let Ok(stmt) = db.prepare("SELECT value FROM t") else:
        print("sqlite3 prepare failed")
        return 1
    if stmt.step() != SQLITE_ROW:
        print("sqlite3 step failed")
        return 1
    if stmt.column_int(0) != 42:
        print("sqlite3 value mismatch")
        return 1
    print("sqlite3 UAT passed")
