module nebula.db

// ===================================================================
// Database — Error Types, RAII, & Safe Wrappers
//
// Demonstrates:
//   - impl Drop for deterministic RAII cleanup
//   - Error types with named fields
//   - extend for method blocks
//   - Implicit Ok(...) wrapping on the happy path
//   - defer for cleanup on error paths
//   - String interpolation for error messages
//   - Result[T, E] propagation with ?
//   - Trait imports from sibling modules
// ===================================================================

use schema.SqlRecord

// --- Error Types ---

pub error DbError =
    | Init(str)
    | Query(str)
    | Busy(str)

// --- Safe Database Wrapper ---
//
// Owns a database handle. Drop closes the connection
// automatically — even on panic or early return via ?.

pub type Database {
    path: str,
    open: bool = false,
    record_count: i64 = 0,
}

// Deterministic destruction. Because `drop` consumes `self` by value,
// we don't need to null out fields to prevent double-frees.
impl Drop for Database:
    fn drop(self: Self):
        if self.open:
            print(f"[db] closing database: {self.path}")

extend Database:
    // Implicit Ok(...) wrapping: the happy path returns Database,
    // the compiler wraps it in Ok(Database) automatically.
    pub fn open(path: str) -> Result[Database, DbError]:
        if path.len() == 0:
            return Err(.Init("empty path"))

        // Happy path — auto-wrapped in Ok(...)
        Database {
            path,
            open: true,
        }

    // Initialize the schema. Returns Result[(), DbError],
    // so the function body implicitly returns Ok(()) at the end.
    pub fn init_schema(self: &Database) -> Result[bool, DbError]:
        if not self.open:
            return Err(.Init("database not open"))
        print(f"[db] schema initialized for {self.path}")
        true
        // implicit Ok(true)

    // Execute raw SQL.
    pub fn execute(self: &Database, sql: str) -> Result[bool, DbError]:
        if not self.open:
            return Err(.Query("database not open"))
        print(f"[db] execute: {sql}")
        true
        // implicit Ok(true)

    // Bulk insert using trait objects. Any type implementing
    // SqlRecord can be inserted — the caller doesn't need to
    // know the concrete type.
    pub fn insert_bulk(self: &Database, records: &[dyn SqlRecord]) -> Result[bool, DbError]:
        if not self.open:
            return Err(.Query("database not open"))

        for rec in records:
            let query = rec.to_insert_query()
            print(f"[db] {query}")

        true
        // implicit Ok(true)

    // Query the record count.
    pub fn count_records(self: &Database) -> Result[i64, DbError]:
        if not self.open:
            return Err(.Query("database not open"))
        self.record_count
