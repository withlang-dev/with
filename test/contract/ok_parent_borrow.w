//! expect-contract: violations=0 ok

// D85 (#2003; spec §16.2b.6): `returns borrow Database from parent
// Database of param 0` hands out the parent connection of the statement
// (sqlite3_db_handle). The contract view names the parent and the param it
// is read through; the audit checks the presented method views through
// that param (acceptance reads the same declared summary), so the borrow
// is tied to the connection: `st.step()` leaves it valid.
use c_import("typedef struct sqlite3 sqlite3;\ntypedef struct sqlite3_stmt sqlite3_stmt;\n#define SQLITE_OK 0\nint sqlite3_open(const char *filename, sqlite3 **ppDb);\nint sqlite3_close(sqlite3 *db);\nint sqlite3_prepare_v2(sqlite3 *db, const char *zSql, int nByte, sqlite3_stmt **ppStmt, const char **pzTail);\nint sqlite3_step(sqlite3_stmt *pStmt);\nint sqlite3_finalize(sqlite3_stmt *pStmt);\nint sqlite3_changes(sqlite3 *db);\nsqlite3 *sqlite3_db_handle(sqlite3_stmt *pStmt);\n")

c facade sqlite:
    resource Database wraps *mut sqlite3
        from sqlite3_open(out param ppDb)
        drop sqlite3_close
        ok SQLITE_OK
    resource Statement wraps *mut sqlite3_stmt
        from sqlite3_prepare_v2(out param ppStmt)
        drop sqlite3_finalize
        ok SQLITE_OK
        borrows param db
    fn sqlite3_prepare_v2
        rename prepare
        param nByte fixed -1
        param pzTail fixed null
    fn sqlite3_step
        lend
    fn sqlite3_changes
        lend
    fn sqlite3_db_handle
        returns borrow Database from parent Database of param 0
        of Statement
        rename database

fn main:
    let db = Database.open(":memory:").unwrap()
    let st = db.prepare("select 1").unwrap()
    let b = st.database().unwrap()
    st.step()
    print(b.changes())
