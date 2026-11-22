//! expect-debug-alloc: leak count=0

// #558: a Task passed as an ordinary async parameter is captured by the spawned
// fiber. The parameter owns that capture, so awaiting it must free its result
// buffer exactly once for both concrete and generic wrappers.
use std.task.Task
async fn echo[T](value: T) -> T: value

async fn await_i32(task: Task[i32]) -> i32: task.await

async fn await_one[T](task: Task[T]) -> T: task.await

async fn main:
    assert(await_i32(echo(11)).await == 11)
    assert(await_one(echo(17)).await == 17)
