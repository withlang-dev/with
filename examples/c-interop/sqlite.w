module c_interop

// ===================================================================
// SQLite Wrapper — C Interop Example
//
// Demonstrates:
//   - c_import for automatic C header binding
//   - unsafe blocks for FFI calls
//   - Safe wrapper types with Drop for RAII cleanup
//   - @[repr(C)] layout control
//   - defer for resource cleanup
//   - Error types with from
//   - Prepared statements and query iteration
//   - Pipeline operators for result processing
// ===================================================================

use c_import("sqlite3.h", link: "sqlite3")

// --- Error Types ---

error SqliteError =
    | OpenFailed(path: str, code: i32, msg: str)
    | ExecFailed(sql: str, code: i32, msg: str)
    | PrepareFailed(sql: str, code: i32, msg: str)
    | BindFailed(param: i32, code: i32)
    | StepFailed(code: i32)
    | ColumnOutOfRange(index: i32, count: i32)
    | NullPointer(context: str)

// --- Safe Database Wrapper ---
//
// Owns a raw *mut sqlite3 handle. Drop closes the connection.

type Database = {
    handle: *mut sqlite3,
    path: str,
}

impl Drop for Database:
    fn drop(self: Self):
        if self.handle != null:
            unsafe { sqlite3_close(self.handle) }
        // self is consumed — no defensive nulling needed

extend Database:
    fn open(path: str) -> Result[Database, SqliteError]:
        var handle: *mut sqlite3 = null
        let rc = unsafe { sqlite3_open(path.as_ptr(), &mut handle) }
        if rc != SQLITE_OK:
            let msg = if handle != null:
                unsafe { sqlite3_errmsg(handle) } |> ptr_to_string
            else:
                "unknown error"
            // Close even on error — sqlite3_open may allocate
            if handle != null:
                unsafe { sqlite3_close(handle) }
            return Err(.OpenFailed(
                path,
                code: rc,
                msg,
            ))
        Database { handle, path }

    fn execute(self: &Self, sql: &str) -> Result[Unit, SqliteError]:
        var err_msg: *mut u8 = null
        let rc = unsafe {
            sqlite3_exec(self.handle, sql.as_ptr(), null, null, &mut err_msg)
        }
        if rc != SQLITE_OK:
            let msg = if err_msg != null:
                let s = unsafe { ptr_to_string(err_msg) }
                unsafe { sqlite3_free(err_msg as *mut void) }
                s
            else:
                "unknown error"
            return Err(.ExecFailed(
                sql: sql.to_string(),
                code: rc,
                msg,
            ))

    fn prepare(self: &Self, sql: &str) -> Result[Statement, SqliteError]:
        var stmt: *mut sqlite3_stmt = null
        let rc = unsafe {
            sqlite3_prepare_v2(self.handle, sql.as_ptr(), -1, &mut stmt, null)
        }
        if rc != SQLITE_OK:
            let msg = unsafe { sqlite3_errmsg(self.handle) } |> ptr_to_string
            return Err(.PrepareFailed(
                sql: sql.to_string(),
                code: rc,
                msg,
            ))
        Statement { handle: stmt }

    fn last_insert_rowid(self: &Self) -> i64:
        unsafe { sqlite3_last_insert_rowid(self.handle) }

    fn changes(self: &Self) -> i32:
        unsafe { sqlite3_changes(self.handle) }

    // --- Transaction Helper ---

    fn transaction[T](
        self: &Self,
        body: fn(&Self) -> Result[T, SqliteError],
    ) -> Result[T, SqliteError]:
        self.execute("BEGIN")?
        match body(self)
            Ok(value) ->
                self.execute("COMMIT")?
                value
            Err(e) ->
                // Rollback, but don't mask the original error
                let _ = self.execute("ROLLBACK")
                Err(e)

// --- Safe Statement Wrapper ---
//
// Owns a raw *mut sqlite3_stmt. Drop finalizes it.

type Statement = {
    handle: *mut sqlite3_stmt,
}

impl Drop for Statement:
    fn drop(self: Self):
        if self.handle != null:
            unsafe { sqlite3_finalize(self.handle) }
        // self is consumed — no defensive nulling needed

extend Statement:
    fn bind_int(self: &Self, param: i32, value: i32) -> Result[Unit, SqliteError]:
        let rc = unsafe { sqlite3_bind_int(self.handle, param, value) }
        if rc != SQLITE_OK:
            return Err(.BindFailed(param, code: rc))

    fn bind_text(self: &Self, param: i32, value: &str) -> Result[Unit, SqliteError]:
        let rc = unsafe {
            sqlite3_bind_text(self.handle, param, value.as_ptr(), value.len32(), SQLITE_TRANSIENT)
        }
        if rc != SQLITE_OK:
            return Err(.BindFailed(param, code: rc))

    fn bind_f64(self: &Self, param: i32, value: f64) -> Result[Unit, SqliteError]:
        let rc = unsafe { sqlite3_bind_double(self.handle, param, value) }
        if rc != SQLITE_OK:
            return Err(.BindFailed(param, code: rc))

    fn step(self: &Self) -> Result[bool, SqliteError]:
        let rc = unsafe { sqlite3_step(self.handle) }
        match rc
            SQLITE_ROW  -> Ok(true)
            SQLITE_DONE -> Ok(false)
            _           -> Err(.StepFailed(code: rc))

    fn reset(self: &Self) -> Result[Unit, SqliteError]:
        let rc = unsafe { sqlite3_reset(self.handle) }
        if rc != SQLITE_OK:
            return Err(.StepFailed(code: rc))

    fn column_count(self: &Self) -> i32:
        unsafe { sqlite3_column_count(self.handle) }

    fn column_int(self: &Self, col: i32) -> i32:
        unsafe { sqlite3_column_int(self.handle, col) }

    fn column_text(self: &Self, col: i32) -> str:
        let ptr = unsafe { sqlite3_column_text(self.handle, col) }
        if ptr == null:
            str.new()
        else:
            unsafe { ptr_to_string(ptr) }

    fn column_f64(self: &Self, col: i32) -> f64:
        unsafe { sqlite3_column_double(self.handle, col) }

// --- Row Iterator ---
//
// Generator that yields rows as the statement is stepped.
// Captures &Statement — generator is ephemeral.

gen fn rows(stmt: &Statement) -> &Statement:
    loop:
        match stmt.step()
            Ok(true)  -> yield stmt
            Ok(false) -> break
            Err(_)    -> break

// --- Helper ---

fn ptr_to_string(ptr: *const u8) -> str:
    if ptr == null:
        str.new()
    else:
        unsafe { str.from_c_str(ptr) }

// --- Main Demo ---

fn main -> Result[Unit, SqliteError]:
    println("=== SQLite C Interop Demo ===\n")

    // Open an in-memory database
    let db = Database.open(":memory:")?
    println("Opened in-memory database")

    // Create table
    db.execute("
        CREATE TABLE users (
            id    INTEGER PRIMARY KEY AUTOINCREMENT,
            name  TEXT NOT NULL,
            email TEXT NOT NULL UNIQUE,
            score REAL DEFAULT 0.0
        )
    ")?
    println("Created users table")

    // Insert with prepared statement inside a transaction
    let inserted = db.transaction(|db|
        let stmt = db.prepare("INSERT INTO users (name, email, score) VALUES (?, ?, ?)")?

        let users = [
            ("Alice",   "alice@example.com",   95.5),
            ("Bob",     "bob@example.com",     82.0),
            ("Charlie", "charlie@example.com", 91.3),
            ("Diana",   "diana@example.com",   78.9),
            ("Eve",     "eve@example.com",     88.7),
        ]

        var count = 0
        for (name, email, score) in users:
            stmt.reset()?
            stmt.bind_text(1, name)?
            stmt.bind_text(2, email)?
            stmt.bind_f64(3, *score)?
            stmt.step()?
            count = count + 1

        println("Inserted {count} users")
        count
    )?
    println("Transaction committed ({inserted} rows)\n")

    // Query with prepared statement
    println("--- All users (score >= 80) ---")
    let query = db.prepare("SELECT id, name, email, score FROM users WHERE score >= ? ORDER BY score DESC")?
    query.bind_f64(1, 80.0)?

    for row in rows(&query):
        let id    = row.column_int(0)
        let name  = row.column_text(1)
        let email = row.column_text(2)
        let score = row.column_f64(3)
        println("  #{id} {name} <{email}> score={score:.1}")

    // Aggregate query
    println("\n--- Stats ---")
    let stats = db.prepare("SELECT COUNT(*), AVG(score), MAX(score), MIN(score) FROM users")?
    if stats.step()?:
        let count = stats.column_int(0)
        let avg   = stats.column_f64(1)
        let max   = stats.column_f64(2)
        let min   = stats.column_f64(3)
        println("  count={count} avg={avg:.1} max={max:.1} min={min:.1}")

    // Update with pipeline
    println("\n--- Bonus round: +5 to everyone ---")
    db.execute("UPDATE users SET score = score + 5.0")?
    println("  updated {db.changes()} rows")

    // Re-query to show updated scores
    let all = db.prepare("SELECT name, score FROM users ORDER BY name")?
    for row in rows(&all):
        println("  {row.column_text(0)}: {row.column_f64(1):.1}")

    // Demonstrate error handling
    println("\n--- Error handling ---")
    match db.execute("INSERT INTO users (name, email) VALUES ('Duplicate', 'alice@example.com')")
        Ok(_)  -> println("  unexpected success")
        Err(e) -> println("  expected error: {e}")

    println("\n=== Demo complete ===")
