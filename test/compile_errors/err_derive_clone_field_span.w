//! expect-check-fail: telemetry.w:6:30
// A derive that fails on a field reports at that field's type, in the
// declaring file, with the remedy named; it used to point at a `use` line of
// the importing file (#1150, examples/nebula).

use derive_field.telemetry

fn main:
    let t = Telemetry { status: .Idle, n: 1 }
    let _ = t.n
