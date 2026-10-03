//! expect-check-fail: use of moved value
// #1993: `join_cleanup()` releases the task (cancel, cleanup await, result
// buffer freed), so it consumes an owned Task binding: a later `.await`
// could only read the released handle. Before, Sema accepted it and the
// await produced a value out of freed storage.
use std.task.Task

async fn word() -> str: "hello" ++ " world"

async fn main:
    let t = word()
    t.join_cleanup()
    let s = t.await
    print(s)
