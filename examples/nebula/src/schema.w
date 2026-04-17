module nebula.schema

// ===================================================================
// Schema — Metaprogramming & Domain Types
//
// Demonstrates:
//   - Algebraic data types with named variant fields
//   - Enum variant shorthand (.Ok)
//   - @[derive] for automatic trait generation
//   - comptime metaprogramming (compile-time reflection)
//   - Trait definitions and implementations
//   - Collection comprehensions
//   - Record update syntax ({ base with field })
//   - Default field values
//   - Field shorthand in struct literals
//   - The `in` operator for membership tests
//   - `with ... as mut` for scoped mutation
// ===================================================================

// --- Domain Types ---

pub type Status =
    | Ok
    | Warning(str)
    | Fatal(code: i32)

@[derive(Debug, Clone)]
pub type Telemetry = {
    device_id: str,
    temp: f64 = 0.0,
    status: Status = .Ok,
}

// --- SQL Record Trait ---
//
// The trait we want to implement automatically via comptime.
// Any type implementing SqlRecord can be serialized to a SQL INSERT.

pub trait SqlRecord:
    fn table_name(self: &Self) -> str
    fn to_insert_query(self: &Self) -> str

// --- Comptime Metaprogramming ---
//
// This function executes at compile time, inspecting T's fields
// to stamp out an `impl SqlRecord` block. The compiler evaluates
// T.name(), T.fields(), and the comprehension at compile time,
// then emits the impl with the computed strings baked in.

pub comptime fn derive_sql_record[T: type] -> impl SqlRecord for T:
    let table = T.name().to_lower()
    let fields = T.fields()

    // Comptime comprehension: builds the column name list at compile time
    let col_names = [f.name for f in fields].join(", ")

    // The generated implementation — body runs at runtime
    impl SqlRecord for T:
        fn table_name(self: &T) -> str: table

        fn to_insert_query(self: &T) -> str:
            // Runtime comprehension: evaluates field values dynamically
            let vals = [self.{f.name}.to_string() for f in fields]
            "INSERT INTO {table} ({col_names}) VALUES ({vals.join(", ")})"

// Trigger the comptime generation for Telemetry
comptime let _ = derive_sql_record[Telemetry]()

// --- Status Helpers ---

pub fn is_fatal(s: &Status) -> bool:
    match s:
        .Fatal(_) => true
        _         => false

pub fn status_label(s: &Status) -> str:
    match s:
        .Ok         => "ok"
        .Warning(w) => "warn: {w}"
        .Fatal(c)   => "fatal({c.code})"

// --- Server Configuration ---
//
// Uses default fields — construct with only the fields that differ.
// Record update syntax creates a new config from an existing one.

pub type ServerConfig = {
    host: str = "0.0.0.0",
    port: u16 = 8080,
    max_clients: usize = 1000,
    idle_timeout_secs: u32 = 30,
    db_path: str = "telemetry.db",
}

pub fn load_config(env_port: Option[u16]) -> ServerConfig:
    let base = ServerConfig {}  // All defaults
    match env_port:
        Some(port) => { base with port }  // Record update + field shorthand
        None       => base

// --- Severity Classification ---
//
// Uses the `in` operator for membership tests against literal arrays.

pub type Severity = Low | Medium | High | Critical

pub fn classify_temp(temp: f64) -> Severity:
    if temp > 100.0 then .Critical
    else if temp > 80.0 then .High
    else if temp > 60.0 then .Medium
    else .Low

pub fn should_alert(sev: Severity) -> bool:
    sev in [.High, .Critical]

// --- Batch Builder ---
//
// Uses `with ... as mut` for scoped mutation to build a telemetry batch.

pub fn build_test_batch(count: usize) -> Vec[Telemetry]:
    with Vec.new() as mut batch:
        for i in 0..count:
            let status = if i % 5 == 0 then .Warning("periodic check")
                         else if i % 10 == 0 then .Fatal(code: 99)
                         else .Ok
            batch.push(Telemetry {
                device_id: "dev-{i}",
                temp: 20.0 + (i as f64) * 0.5,
                status,
            })
