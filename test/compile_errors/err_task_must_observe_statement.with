//! expect-error: E0801: task result must be observed

@[must_use]
async fn send_invoice() -> i32:
    42

async fn main:
    send_invoice()
    let done = 1
