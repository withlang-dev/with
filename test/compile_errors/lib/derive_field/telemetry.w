use derive_field.status

// The field whose type lacks Clone; the derive error points here, in this
// file, not at the importer's `use` line.
@[derive(Clone)]
pub type Telemetry { status: Status, n: i32 }
