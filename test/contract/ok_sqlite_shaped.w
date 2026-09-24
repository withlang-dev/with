//! expect-contract: contract-audit: resources=2 items=9 domains=1 conventions=0 advisories=0 profile-ambiguous=0 profile-shadowed=0
//! expect-contract: violations=0 ok

// D51 stage 10 (ruling §63, spec §16.2b): a facaded SQLite-shaped header,
// clean. `with analyze <this> contract` prints every effective fact with its
// provenance (ok_sqlite_shaped.expected); `audit:contract` is green.

use c_import("typedef struct sqlite3 sqlite3;\ntypedef struct sqlite3_stmt sqlite3_stmt;\n#define SQLITE_OK 0\nint sqlite3_open(const char *filename, sqlite3 **ppDb);\nint sqlite3_close(sqlite3 *db);\nint sqlite3_close_v2(sqlite3 *db);\nint sqlite3_prepare_v2(sqlite3 *db, const char *zSql, int nByte, sqlite3_stmt **ppStmt);\nint sqlite3_step(sqlite3_stmt *pStmt);\nint sqlite3_finalize(sqlite3_stmt *pStmt);\nconst char *sqlite3_errmsg(sqlite3 *db);\nconst char *sqlite3_column_text(sqlite3_stmt *pStmt, int iCol);\nsqlite3 *sqlite3_db_handle(sqlite3_stmt *pStmt);\nint sqlite3_create_function_v2(sqlite3 *db, const char *zName, int nArg, int eTextRep, void *pApp, void (*xFunc)(void *), void (*xDestroy)(void *));\nint sqlite3_trace_v2(sqlite3 *db, unsigned mask, int (*xCallback)(unsigned, void *, void *, void *), void *pCtx);\nconst char *sqlite3_libversion(void);\n")

c facade sqlite:
    domain errno thread
    resource Database wraps *mut sqlite3
        from sqlite3_open(out param ppDb)
        drop sqlite3_close
        destroys sqlite3_close_v2
        ok SQLITE_OK
        thread send drop_any_thread
    resource Statement wraps *mut sqlite3_stmt
        from sqlite3_prepare_v2(out param ppStmt)
        drop sqlite3_finalize
        ok SQLITE_OK
        borrows param db
    fn sqlite3_close_v2
        destroys
    fn sqlite3_prepare_v2
        rename prepare
    fn sqlite3_step
        lend
    fn sqlite3_errmsg
        returns borrow CStr from param 0
        preserves param 0
    fn sqlite3_column_text
        returns borrow CStr from param 0
        preserves param 0
    fn sqlite3_db_handle
        returns borrow Database from param 0
        of Statement
        rename database
    fn sqlite3_create_function_v2
        consumes param pApp destroyed_by param xDestroy
        preserves domain errno
        callback_thread any
    fn sqlite3_trace_v2
        retains param xCallback by param db
        retains param pCtx by param db
    fn sqlite3_libversion
        returns static CStr

fn main:
    print("ok")
