use c_import("sqlite3.h")

fn main:
    var db: *mut sqlite3 = null
    var stmt: *mut sqlite3_stmt = null

    let open_rc = unsafe { sqlite3_open(c":memory:".ptr, &raw mut db as *mut *mut sqlite3) }
    if open_rc != SQLITE_OK:
        print("sqlite3 open failed")
        return 1

    let create_rc = unsafe { sqlite3_exec(db, c"CREATE TABLE t(value INTEGER); INSERT INTO t(value) VALUES (42);".ptr, null, null, null) }
    if create_rc != SQLITE_OK:
        print("sqlite3 exec failed")
        unsafe { sqlite3_close(db) }
        return 1

    let prep_rc = unsafe { sqlite3_prepare_v2(db, c"SELECT value FROM t".ptr, -1, &raw mut stmt as *mut *mut sqlite3_stmt, null) }
    if prep_rc != SQLITE_OK:
        print("sqlite3 prepare failed")
        unsafe { sqlite3_close(db) }
        return 1

    let step_rc = unsafe { sqlite3_step(stmt) }
    if step_rc != SQLITE_ROW:
        print("sqlite3 step failed")
        unsafe { sqlite3_finalize(stmt) }
        unsafe { sqlite3_close(db) }
        return 1

    let value = unsafe { sqlite3_column_int(stmt, 0) }
    unsafe { sqlite3_finalize(stmt) }
    unsafe { sqlite3_close(db) }

    if value != 42:
        print("sqlite3 value mismatch")
        return 1
    write("sqlite3 UAT passed\n")
