use std.builtins.print_i32
use std.task.Task
use std.task.await_all
async fn mark(idx: i32) -> i32: idx * 2 + 1
fn build_tasks(n: i32) -> Vec[Task[i32]]:
    var tasks: Vec[Task[i32]] = Vec.new()
    var i = 0
    while i < n:
        tasks.push(mark(i))
        i = i + 1
    tasks
async fn main:
    let results = await_all(build_tasks(3000))
    print_i32(results.len() as i32)
    print_i32(results.get(1023))
    print_i32(results.get(1024))
    print_i32(results.get(1025))
    print_i32(results.get(2000))
    print_i32(results.get(2999))
