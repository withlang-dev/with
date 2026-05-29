//! expect-error: channel send requires Send value

use std.channel

fn send_ref(tx: Sender[&i32], x: &i32):
    tx.send(x)
