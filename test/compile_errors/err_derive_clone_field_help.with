//! expect-check-fail: = help: add `@[derive(Clone)]` to the declaration of 'Status', or implement Clone for it
// A derive that fails on a field names the remedy.

// A resource (its Drop impl): neither Copy nor Clone. An enum of plain
// variants would be a value (#2549).
enum Status { Idle, Busy }
impl Drop for Status:
    move fn drop(): ()

@[derive(Clone)]
type Telemetry { status: Status, n: i32 }

fn main:
    let t = Telemetry { status: .Idle, n: 1 }
    let _ = t.n
