//! expect-exit: 134
//! expect-stderr: await_first: empty input

use std.task.Task
use std.task.await_first
fn main:
    let tasks: List[Task[i32]] = List.new()
    let _ = tasks |> await_first
