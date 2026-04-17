module nebula.db

// ===================================================================
// Database — C-Interop, unsafe, & Resource Safety
//
// Demonstrates:
//   - c_import for automatic C header binding (sqlite3)
//   - unsafe blocks for raw FFI calls
//   - impl Drop for deterministic RAII cleanup
//   - @[no_await_guard] compliance (Mutex inside with-block)
//   - Implicit Ok(...) wrapping on the happy path
//   - Implicit Ok(()) / Unit returns
//   - Error types with named fields
//   - defer for cleanup on error paths
//   - c"..." string literals for NUL-terminated C strings
//   - Pipeline operators for error message construction
// ===================================================================

use c_import("sqlite3.h", link: "sqlite3")
use nebula.schema.SqlRecord

// --- Error Types ---

pub error DbError =
    | Init(reason: str)
    | Query(sql: str, reason: str)
    | Busy(str)

// --- Safe Database Wrapper ---
//
// Owns a raw *mut sqlite3 handle. Drop closes the connection
// automatically — even on panic or early return via ?.
// The Mutex ensures thread-safe access from multiple fibers.

pub type Database {
    handle: *mut sqlite3,
    path: str,
    lock: Mutex[Unit],
}

// Deterministic destruction. Because `drop` consumes `self` by value,
// we don't need to null out `handle` to prevent double-frees.
impl Drop for Database:
    fn drop(self: Self):
        if self.handle != null:
            unsafe { sqlite3_close(self.handle) }

extend Database:
    // Implicit Ok(...) wrapping: the happy path returns Database,
    // the compiler wraps it in Ok(Database) automatically.
    pub fn open(path: &str) -> Result[Database, DbError]:
        var handle: *mut sqlite3 = null

        let rc = unsafe { sqlite3_open(path.as_ptr(), &mut handle) }
        if rc != SQLITE_OK:
            // Clean up even on error — sqlite3_open may allocate
            if handle != null:
                unsafe { sqlite3_close(handle) }
            return Err(.Init("failed to open: {path}"))

        // Happy path — auto-wrapped in Ok(...)
        Database {
            handle,
            path: path.to_string(),
            lock: Mutex.new(()),
        }

    // Initialize the schema. Returns Result[Unit, DbError],
    // so the function body implicitly returns Ok(()) at the end.
    pub fn init_schema(self: &Database) -> Result[Unit, DbError]:
        self.execute("
            CREATE TABLE IF NOT EXISTS telemetry (
                id        INTEGER PRIMARY KEY AUTOINCREMENT,
                device_id TEXT    NOT NULL,
                temp      REAL    NOT NULL,
                status    TEXT    NOT NULL,
                ts        INTEGER DEFAULT (strftime('%s','now'))
            )
        ")?
        self.execute("CREATE INDEX IF NOT EXISTS idx_device ON telemetry(device_id)")
        // implicit Ok(())

    // Execute raw SQL. Demonstrates c"..." string literals and
    // pipeline operator for error message formatting.
    pub fn execute(self: &Database, sql: &str) -> Result[Unit, DbError]:
        var err_msg: *mut u8 = null
        let rc = unsafe {
            sqlite3_exec(self.handle, sql.as_ptr(), null, null, &mut err_msg)
        }
        if rc != SQLITE_OK:
            let reason = if err_msg != null:
                let s = unsafe { ptr_to_string(err_msg) }
                unsafe { sqlite3_free(err_msg as *mut void) }
                s
            else:
                "unknown error"
            return Err(.Query(sql: sql.to_string(), reason))
        // implicit Ok(())

    // Synchronous bulk insert. Uses @[no_await_guard]-safe Mutex:
    // the compiler would reject any .await inside the `with` block.
    pub fn insert_bulk(self: &Database, records: &[dyn SqlRecord]) -> Result[Unit, DbError]:
        with self.lock.lock() as _:
            unsafe { sqlite3_exec(self.handle, c"BEGIN".ptr, null, null, null) }

            for rec in records:
                let query = rec.to_insert_query()
                let rc = unsafe {
                    sqlite3_exec(self.handle, query.as_ptr(), null, null, null)
                }
                if rc != SQLITE_OK:
                    unsafe { sqlite3_exec(self.handle, c"ROLLBACK".ptr, null, null, null) }
                    return Err(.Query(sql: query, reason: "insert failed"))

            unsafe { sqlite3_exec(self.handle, c"COMMIT".ptr, null, null, null) }
        // implicit Ok(())

    // Query the latest N records. Returns a count for now —
    // a full implementation would return parsed Telemetry records.
    pub fn count_records(self: &Database) -> Result[i64, DbError]:
        var stmt: *mut sqlite3_stmt = null
        let rc = unsafe {
            sqlite3_prepare_v2(
                self.handle,
                c"SELECT COUNT(*) FROM telemetry".ptr,
                -1,
                &mut stmt,
                null,
            )
        }
        if rc != SQLITE_OK:
            return Err(.Query(
                sql: "SELECT COUNT(*)",
                reason: "prepare failed",
            ))
        defer unsafe { sqlite3_finalize(stmt) }

        if unsafe { sqlite3_step(stmt) } == SQLITE_ROW:
            unsafe { sqlite3_column_int64(stmt, 0) }
        else:
            0

// --- C-Callback Stress Test ---
//
// extern "C" marks a function as using C calling convention,
// suitable for passing as a callback to sqlite3_trace().

extern "C" fn on_sqlite_trace(ctx: *mut c_void, sql: *const c_char) -> i32

// --- Helper ---

fn ptr_to_string(ptr: *const u8) -> str:
    if ptr == null:
        str.new()
    else:
        unsafe { str.from_c_str(ptr) }
