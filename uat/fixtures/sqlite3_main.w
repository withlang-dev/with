// Release UAT: SQLite through its facade (D51, D92; spec §16.2b). The
// program an application developer writes over `with get c.sqlite3`: the
// facade `facades.sqlite3` is the project's own (§16.2b.1), and the raw
// import names the status constants. No `unsafe`, no raw pointer, no status
// code checked by hand: every call that can fail is a `Result` whose error
// carries SQLite's own message, and the statement is finalized and the
// connection closed by their scopes on every path, the statement first
// (§16.2b.6).
use facades.sqlite3
use c_import("sqlite3.h")

error QueryError from DatabaseError, ExecError, StatementError, StepError

fn total(db: &Database) -> Result[i32, QueryError]:
    db.exec("CREATE TABLE t(value INTEGER); INSERT INTO t(value) VALUES (40), (2);")?
    let stmt = db.prepare("SELECT value FROM t")?
    var sum = 0
    while stmt.step()? == SQLITE_ROW: sum += stmt.column_int(0)
    sum

fn main:
    let Ok(db) = Database.open(":memory:") else:
        print("sqlite3 open failed")
        return 1
    match total(db):
        Ok(42) => {}
        Ok(sum) =>
            print(f"sqlite3 sum mismatch: {sum}")
            return 1
        Err(e) =>
            print(f"sqlite3 failed: {e}")
            return 1
    // A failure is a value that says what SQLite said.
    match db.exec("SELEC 1"):
        Err(.Failed(_, message)) =>
            if not message.contains("syntax error"):
                print(f"sqlite3 error text missing: {message}")
                return 1
        Ok(_) =>
            print("sqlite3 accepted invalid SQL")
            return 1
    print("sqlite3 UAT passed")
