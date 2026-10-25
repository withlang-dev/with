//! expect-exit: 134
//! expect-stderr: spawn: as many tasks are running as one program holds at once
// #995: a spawn past the live-task limit stops the program. It returned -1,
// the Task kept it as a fiber id, and awaiting that Task gave 0, a result no
// fiber wrote: 1100 sleeping tasks awaited to 1024 right answers and 76
// zeros.
use std.task.Task
use std.task.await_all
use std.time

async fn mark(i: i32) -> i32:
    sleep(200).await
    i + 1

fn main:
    var tasks: List[Task[i32]] = List.new()
    for i in 0..1100: tasks.push(mark(i))
    let results = await_all(tasks)
    print(results[1099])
