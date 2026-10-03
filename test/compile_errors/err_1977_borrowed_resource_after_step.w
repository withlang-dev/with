//! expect-error: view `b` borrows from `st`, which `sqlite3_step` may have invalidated

// #1977, D51 §38 / spec §16.2b.7 ("unknown effect means invalidate"):
// whether `step` invalidates a borrowed database handle is not inferred
// from the handle's type — inferring "not invalidated" can create
// unsafety — so `step` with no `preserves` invalidates every view of the
// statement, the `BorrowedDatabase` included. The audit fix
// (contract/ok_borrowed_resource_effect.w) leaves this refusal as it was.
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
        returns borrow Database from param 0
        of Statement
        rename database

fn main:
    let db = Database.open(":memory:").unwrap()
    let st = db.prepare("select 1").unwrap()
    let b = st.database().unwrap()
    st.step()
    print(b.changes())
