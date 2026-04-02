//! expect-stdout: ok

// Async blocks currently execute synchronously (v1 limitation).
// This test verifies the block body evaluates correctly.

async fn main:
    let x = 10
    let y = 20
    let result = async:
        x + y
    assert(result == 30)
    print("ok")
