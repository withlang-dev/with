//! expect-check-fail: = help: add `@[derive(Clone)]` to the declaration of 'Status', or implement Clone for it
// A derive that fails on a field names the remedy.

enum Status { Idle, Busy }

@[derive(Clone)]
type Telemetry { status: Status, n: i32 }

fn main:
    let t = Telemetry { status: .Idle, n: 1 }
    let _ = t.n
