// ===================================================================
// SQLite Wrapper — C Interop Example
//
// Demonstrates:
//   - extern fn for C function declarations
//   - unsafe blocks for FFI calls
//   - Opaque pointer types (*mut i8) for C handles
//   - Safe wrapper types for RAII cleanup
//   - defer for resource management
//   - Error types for FFI error codes
//   - Prepared statements and query iteration
// ===================================================================

// --- SQLite C bindings via extern fn ---

extern fn sqlite3_open(filename: *const i8, db: *mut *mut i8) -> i32
extern fn sqlite3_close(db: *mut i8) -> i32
extern fn sqlite3_exec(db: *mut i8, sql: *const i8, callback: *const i8, arg: *const i8, errmsg: *mut *mut i8) -> i32
extern fn sqlite3_prepare_v2(db: *mut i8, sql: *const i8, nbyte: i32, stmt: *mut *mut i8, tail: *mut *const i8) -> i32
extern fn sqlite3_step(stmt: *mut i8) -> i32
extern fn sqlite3_finalize(stmt: *mut i8) -> i32
extern fn sqlite3_reset(stmt: *mut i8) -> i32
extern fn sqlite3_bind_int(stmt: *mut i8, col: i32, value: i32) -> i32
extern fn sqlite3_bind_text(stmt: *mut i8, col: i32, text: *const i8, nbytes: i32, destructor: *const i8) -> i32
extern fn sqlite3_column_int(stmt: *mut i8, col: i32) -> i32
extern fn sqlite3_column_text(stmt: *mut i8, col: i32) -> *const i8
extern fn sqlite3_column_count(stmt: *mut i8) -> i32
extern fn sqlite3_errmsg(db: *mut i8) -> *const i8
extern fn sqlite3_changes(db: *mut i8) -> i32
extern fn sqlite3_free(ptr: *mut i8)

let SQLITE_OK = 0
let SQLITE_ROW = 100
let SQLITE_DONE = 101

// --- Error Type ---

error SqliteError =
    OpenFailed(code: i32)
    | ExecFailed(code: i32)
    | PrepareFailed(code: i32)
    | StepFailed(code: i32)
    | BindFailed(param: i32, code: i32)

// --- Safe Database Wrapper ---

type Database {
    handle: *mut i8,
}

extend Database:
    fn open(path: str) -> Result[Database, SqliteError]:
        var handle: *mut i8 = null
        let rc = sqlite3_open(path.c_str(), &mut handle)
        if rc != SQLITE_OK:
            if handle != null:
                sqlite3_close(handle)
            return Err(.OpenFailed(code: rc))
        Ok(Database { handle })

    fn close(self: Database):
        if self.handle != null:
            sqlite3_close(self.handle)

    fn execute(self: Database, sql: str) -> Result[i32, SqliteError]:
        var err_msg: *mut i8 = null
        let rc = sqlite3_exec(self.handle, sql.c_str(), null, null, &mut err_msg)
        if rc != SQLITE_OK:
            if err_msg != null:
                sqlite3_free(err_msg)
            return Err(.ExecFailed(code: rc))
        Ok(sqlite3_changes(self.handle))

    fn prepare(self: Database, sql: str) -> Result[Statement, SqliteError]:
        var stmt: *mut i8 = null
        var tail: *const i8 = null
        let rc = sqlite3_prepare_v2(self.handle, sql.c_str(), -1, &mut stmt, &mut tail)
        if rc != SQLITE_OK:
            return Err(.PrepareFailed(code: rc))
        Ok(Statement { handle: stmt })

// --- Safe Statement Wrapper ---

type Statement {
    handle: *mut i8,
}

extend Statement:
    fn finalize(self: Statement):
        if self.handle != null:
            sqlite3_finalize(self.handle)

    fn bind_int(self: Statement, param: i32, value: i32) -> Result[i32, SqliteError]:
        let rc = sqlite3_bind_int(self.handle, param, value)
        if rc != SQLITE_OK:
            return Err(.BindFailed(param, code: rc))
        Ok(0)

    fn bind_text(self: Statement, param: i32, value: str) -> Result[i32, SqliteError]:
        let rc = sqlite3_bind_text(self.handle, param, value.c_str(), -1, null)
        if rc != SQLITE_OK:
            return Err(.BindFailed(param, code: rc))
        Ok(0)

    fn step(self: Statement) -> Result[bool, SqliteError]:
        let rc = sqlite3_step(self.handle)
        if rc == SQLITE_ROW:
            Ok(true)
        else if rc == SQLITE_DONE:
            Ok(false)
        else:
            Err(.StepFailed(code: rc))

    fn reset_stmt(self: Statement) -> Result[i32, SqliteError]:
        let rc = sqlite3_reset(self.handle)
        if rc != SQLITE_OK:
            return Err(.StepFailed(code: rc))
        Ok(0)

    fn column_int(self: Statement, col: i32) -> i32:
        sqlite3_column_int(self.handle, col)

    fn column_text(self: Statement, col: i32) -> str:
        let ptr = sqlite3_column_text(self.handle, col)
        if ptr == null:
            ""
        else:
            str.from_c_str(ptr)

// --- Main Demo ---

fn main:
    print("=== SQLite C Interop Demo ===\n")

    match Database.open(":memory:"):
        Ok(db) =>
            print("Opened in-memory database")

            // Create table
            match db.execute("CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT, score INTEGER)"):
                Ok(_) => print("Created users table")
                Err(e) => print("Error creating table: {e}")

            // Insert data with prepared statement
            match db.prepare("INSERT INTO users (name, score) VALUES (?, ?)"):
                Ok(stmt) =>
                    let names = ["Alice", "Bob", "Charlie"]
                    let scores = [95, 82, 91]
                    for i in 0..3:
                        stmt.reset_stmt()
                        stmt.bind_text(1, names[i])
                        stmt.bind_int(2, scores[i])
                        stmt.step()
                    stmt.finalize()
                    print("Inserted 3 users")
                Err(e) => print("Prepare error: {e}")

            // Query data
            print("\n--- All users ---")
            match db.prepare("SELECT id, name, score FROM users ORDER BY score DESC"):
                Ok(query) =>
                    while true:
                        match query.step():
                            Ok(true) =>
                                let id = query.column_int(0)
                                let name = query.column_text(1)
                                let score = query.column_int(2)
                                print("  #{id} {name} score={score}")
                            Ok(false) => break
                            Err(_) => break
                    query.finalize()
                Err(e) => print("Query error: {e}")

            db.close()
            print("\n=== Demo complete ===")

        Err(e) =>
            print("Failed to open database: {e}")
