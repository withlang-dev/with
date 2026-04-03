//! expect-exit: 1
//! expect-stdout: done

// Fire-and-forget spawn of a panicking fiber.
// Main prints "done", then with_runtime_run drains and reports
// the unhandled panic, exiting with code 1.

async fn bad() -> i32:
    assert(false)
    0

async fn main:
    spawn bad()
    print("done")
