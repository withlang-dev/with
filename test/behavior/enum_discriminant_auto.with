//! expect-stdout: ok

enum Status: i32:
    Ready
    | Running
    | Done
    | Failed = 10
    | Cancelled

fn main:
    // Auto-increment from 0
    assert(Status.Ready == 0)
    assert(Status.Running == 1)
    assert(Status.Done == 2)
    // Explicit value resets auto-increment
    assert(Status.Failed == 10)
    assert(Status.Cancelled == 11)
    print("ok")
