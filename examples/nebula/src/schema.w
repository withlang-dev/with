module nebula.schema

// ===================================================================
// Schema — Domain Types & Traits
//
// Demonstrates:
//   - Algebraic data types with named variant fields
//   - Enum variant shorthand (.Ok)
//   - @[derive] for automatic trait generation
//   - Trait definitions and implementations
//   - Record update syntax ({ base with field })
//   - Default field values
//   - Field shorthand in struct literals
//   - The `in` operator for membership tests
//   - `with ... as mut` for scoped mutation
// ===================================================================

// --- Domain Types ---

pub enum Status {
    Active
    | Warning(str)
    | Fatal(code: i32)
}

@[derive(Debug, Clone)]
pub type Telemetry {
    device_id: str,
    temp: f64 = 0.0,
    status: Status = .Active,
}

// --- SQL Record Trait ---
//
// Any type implementing SqlRecord can be serialized to a SQL INSERT.

pub trait SqlRecord:
    fn table_name(self: &Self) -> str
    fn to_insert_query(self: &Self) -> str

// --- Manual SqlRecord Implementation for Telemetry ---
//
// In a full implementation, comptime metaprogramming would generate
// this automatically by inspecting T's fields at compile time.

impl SqlRecord for Telemetry:
    fn table_name(self: &Telemetry) -> str:
        "telemetry"

    fn to_insert_query(self: &Telemetry) -> str:
        f"INSERT INTO telemetry (device_id, temp) VALUES ('{self.device_id}', {self.temp})"

// --- Status Helpers ---

pub fn is_fatal(s: Status) -> bool:
    match s:
        .Fatal(_) => true
        _         => false

pub fn status_label(s: Status) -> str:
    match s:
        .Active     => "ok"
        .Warning(w) => f"warn: {w}"
        .Fatal(c)   => f"fatal({c})"

// --- Server Configuration ---
//
// Uses default fields — construct with only the fields that differ.
// Record update syntax creates a new config from an existing one.

pub type ServerConfig {
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

pub enum Severity { Low | Medium | High | Critical }

pub fn classify_temp(temp: f64) -> Severity:
    if temp > 100.0: .Critical
    else if temp > 80.0: .High
    else if temp > 60.0: .Medium
    else .Low

pub fn should_alert(sev: Severity) -> bool:
    sev in [.High, .Critical]

// --- Batch Builder ---
//
// Uses `with ... as mut` for scoped mutation to build a telemetry batch.

pub fn build_test_batch(count: usize) -> Vec[Telemetry]:
    with Vec.new() as mut batch:
        for i in 0..count:
            let status = if i % 5 == 0: .Warning("periodic check")
                         else if i % 10 == 0: .Fatal(code: 99)
                         else .Active
            batch.push(Telemetry {
                device_id: f"dev-{i}",
                temp: 20.0 + (i as f64) * 0.5,
                status,
            })
