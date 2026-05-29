//! check-only

async fn fetch(id: i32) -> i32:
    id + 1

async fn process(value: &i32) -> i32:
    *value

fn owned_argument_task_is_storable:
    let task = fetch(42)
    var tasks = Vec[Task[i32]].new()
    tasks.push(task)

async fn borrowing_task_is_scoped:
    let value = 42
    async scope s =>:
        let task = s.track(process(&value))
        task.await

fn main:
    owned_argument_task_is_storable()
