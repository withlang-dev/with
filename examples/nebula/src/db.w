module nebula.db

// ===================================================================
// Database — Error Types, RAII, & Safe Wrappers
//
// Demonstrates:
//   - impl Drop for deterministic RAII cleanup
//   - Error types with named fields
//   - extend for method blocks
//   - Implicit Ok(...) wrapping on the happy path
//   - Implicit Ok(()) for Result[Unit, E] functions
//   - String interpolation for error messages
//   - Result[T, E] propagation with ?
//   - Trait bounds on generic functions
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

// Deterministic destruction. `drop` consumes `self` (§2.4), so there is
// no need to null out fields to prevent double-frees.
impl Drop for Database:
    move fn drop():
        if self.open:
            print(f"[db] closing database: {self.path}")

// A constructor has no receiver, so it is a function of the type (§3.1).
// Implicit Ok(...) wrapping: the happy path returns Database, the
// compiler wraps it in Ok(Database) automatically.
pub fn Database.open(path: str) -> Result[Database, DbError]:
    if path.len() == 0:
        return Err(.Init("empty path"))

    // Happy path — auto-wrapped in Ok(...)
    Database {
        path,
        open: true,
    }

extend Database:
    // Initialize the schema. Returns Result[Unit, DbError], so the
    // function body implicitly returns Ok(()) at the end.
    pub fn init_schema() -> Result[Unit, DbError]:
        if not self.open:
            return Err(.Init("database not open"))
        print(f"[db] schema initialized for {self.path}")
        // implicit Ok(())

    // Execute raw SQL.
    pub fn execute(sql: str) -> Result[Unit, DbError]:
        if not self.open:
            return Err(.Query("database not open"))
        print(f"[db] execute: {sql}")
        // implicit Ok(())

    // Bulk insert through the SqlRecord trait. Any type implementing
    // SqlRecord can be inserted — the caller doesn't need to
    // know the concrete type.
    pub fn insert_bulk[R: SqlRecord](records: &Vec[R]) -> Result[Unit, DbError]:
        if not self.open:
            return Err(.Query("database not open"))

        for rec in records:
            let query = rec.to_insert_query()
            print(f"[db] {query}")
        // implicit Ok(())

    // Query the record count.
    pub fn count_records() -> Result[i64, DbError]:
        if not self.open:
            return Err(.Query("database not open"))
        self.record_count
