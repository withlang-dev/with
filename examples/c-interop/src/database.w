// Importing a C library, and owning what it hands out.
//
// `c_import` reads sqlite3.h: its functions, its opaque handle types and its
// `#define` constants arrive as With declarations. Nothing is declared by hand.
//
// SQLite's handles are raw pointers, and a raw pointer is the one thing With
// cannot prove. So this module is where `unsafe` lives: each block is one C
// call whose contract SQLite's documentation states. Everything `pub` is
// safe, and a program that uses `Database` never writes `unsafe`.

use c_import("sqlite3.h", link: "sqlite3")

pub error DbError = Failed(code: i32, message: str)

// SQLite reports failure as a code, and keeps the message on the connection
// until the next call replaces it: copy it now.
fn check(db: *mut sqlite3, code: i32) -> Result[Unit, DbError]:
    if code != SQLITE_OK:
        return Err(.Failed(code, message: unsafe { CStr.from_ptr(sqlite3_errmsg(db)) }.to_str()))

// A connection. Dropping it closes it, on every path, `?` included.
pub type Database { handle: *mut sqlite3 }

impl Drop for Database:
    move fn drop(): unsafe { sqlite3_close(self.handle) }

// A prepared statement. Dropping it finalizes it.
pub type Statement { handle: *mut sqlite3_stmt, db: *mut sqlite3 }

impl Drop for Statement:
    move fn drop(): unsafe { sqlite3_finalize(self.handle) }

pub fn Database.open(path: &str) -> Result[Database, DbError]:
    var handle: *mut sqlite3 = null
    let code = unsafe { sqlite3_open(path, &raw mut handle) }
    // SQLite hands back a handle even when it fails, so that the message can
    // be read from it. Owning it first means the failure closes it.
    let db = Database { handle }
    check(handle, code)?
    db

extend Database:
    // Run statements that return no rows; the number of rows they changed.
    pub fn execute(sql: &str) -> Result[i32, DbError]:
        check(self.handle, unsafe { sqlite3_exec(self.handle, sql, null, null, null) })?
        unsafe { sqlite3_changes(self.handle) }

    pub fn prepare(sql: &str) -> Result[Statement, DbError]:
        var handle: *mut sqlite3_stmt = null
        check(self.handle, unsafe { sqlite3_prepare_v2(self.handle, sql, -1, &raw mut handle, null) })?
        Statement { handle, db: self.handle }

extend Statement:
    // Parameters are numbered from 1, as SQLite numbers them.
    pub fn bind_int(index: i32, value: i32) -> Result[Unit, DbError]:
        check(self.db, unsafe { sqlite3_bind_int(self.handle, index, value) })

    // SQLITE_TRANSIENT: SQLite copies the text before the call returns.
    pub fn bind_text(index: i32, value: &str) -> Result[Unit, DbError]:
        check(self.db, unsafe { sqlite3_bind_text(self.handle, index, value, -1, SQLITE_TRANSIENT) })

    // Advance to the next row; false when there are no more.
    pub fn step() -> Result[bool, DbError]:
        let code = unsafe { sqlite3_step(self.handle) }
        if code != SQLITE_ROW and code != SQLITE_DONE: check(self.db, code)?
        code == SQLITE_ROW

    pub fn reset() -> Result[Unit, DbError]:
        check(self.db, unsafe { sqlite3_reset(self.handle) })

    // Columns are numbered from 0, as SQLite numbers them.
    pub fn int(column: i32) -> i32: unsafe { sqlite3_column_int(self.handle, column) }

    // NULL is information: a NULL column is None, not "".
    pub fn text(column: i32) -> Option[str]:
        let text = unsafe { sqlite3_column_text(self.handle, column) }
        text.as_option().map(p => unsafe { CStr.from_ptr(p) }.to_str())
