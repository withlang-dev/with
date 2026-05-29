//! expect-check-fail: ephemeral Task cannot be created on OS thread

use std.thread

async fn process(value: &i32) -> i32:
    *value + 1

fn worker() -> i32:
    let data = 41
    let task = process(&data)
    0

fn main:
    let handle = spawn_os(worker)
    let _ = join(handle)
