use std.builtins.print_i32
use std.task.Task
use std.task.await_all
async fn mark(idx: i32) -> Result[i32, str]: Ok(idx + 1)
fn build_tasks(n: i32) -> Vec[Task[Result[i32, str]]]:
    var tasks: Vec[Task[Result[i32, str]]] = Vec.new()
    var i = 0
    while i < n:
        tasks.push(mark(i))
        i = i + 1
    tasks
async fn main:
    match await_all(build_tasks(1100)):
        Ok(results) => { print_i32(results.len() as i32) }
        Err(e) => { print_i32(-1) }
