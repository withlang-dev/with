// Release UAT: SQLite through its facade (D51, D92; spec §16.2b). The
// program an application developer writes over `with get c.sqlite3`. No
// `unsafe`, no raw pointer, no status code compared by hand: every call that
// can fail is a `Result`, the statement is finalized and the connection
// closed by their scopes on every path, and a failure carries SQLite's own
// message.
use facades.sqlite3
use c_import("sqlite3.h")

error QueryError from DatabaseError, ExecError, StatementError, StepError

fn sum_values(db: &Database) -> Result[i32, QueryError]:
    db.exec("CREATE TABLE t(value INTEGER); INSERT INTO t(value) VALUES (40), (2);")?
    let stmt = db.prepare("SELECT value FROM t")?
    var total = 0
    while stmt.step()? == SQLITE_ROW: total += stmt.column_int(0)
    total

fn main:
    let Ok(db) = Database.open(":memory:") else:
        print("sqlite3 open failed")
        return 1
    match sum_values(db):
        .Ok(42) => {}
        .Ok(total) =>
            print(f"sqlite3 sum mismatch: {total}")
            return 1
        .Err(e) =>
            print(f"sqlite3 failed: {e}")
            return 1
    // A failure is an error value that says what SQLite said.
    match db.exec("SELEC 1"):
        .Err(.Failed(_, message)) =>
            if not message.contains("syntax error"):
                print(f"sqlite3 error text missing: {message}")
                return 1
        .Ok(_) =>
            print("sqlite3 accepted invalid SQL")
            return 1
    print("sqlite3 UAT passed")
