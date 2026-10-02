//! expect-exit: 134
//! expect-stderr: await_first: empty input

use std.task.Task
use std.task.await_first
fn main:
    let tasks: Vec[Task[i32]] = Vec.new()
    let _ = tasks |> await_first
