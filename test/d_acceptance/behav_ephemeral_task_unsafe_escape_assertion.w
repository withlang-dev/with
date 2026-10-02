//! expect-stdout: ok

use std.task.Task
async fn process(value: &i32) -> i32:
    *value + 1

fn unchecked_sink(task: Task[i32]) -> Task[i32]:
    task

fn main:
    let value = 41
    let task = process(&value)
    // #D5 share-place: transferring the ephemeral task out of the caller is now
    // an explicit, safe ownership transfer (`move`) — the previous `unsafe`
    // escape hatch is no longer needed (and would be an empty unsafe block).
    let returned = unchecked_sink(move task)
    returned.cancel()
    print("ok")
