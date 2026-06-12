//! expect-stdout: ok

async fn fetch_data(id: i32) -> i32:
    id + 1

async fn send_analytics(event: i32):
    let _ = event

fn start_fetch(id: i32) -> Task[i32]:
    fetch_data(id)

fn pass_task(task: Task[i32]) -> Task[i32]:
    task

trait DataSource:
    async fn fetch(self: &Self, id: i32) -> i32

type RemoteDb {
    base: i32,
}

impl DataSource for RemoteDb:
    async fn fetch(self: &Self, id: i32) -> i32:
        self.base + id

fn test_regular_function_can_call_async:
    let task = start_fetch(41)
    assert(task.await == 42)

fn test_task_values_can_be_passed_and_stored:
    let task = fetch_data(9)
    let passed = pass_task(move task)
    assert(passed.await == 10)

    var tasks = Vec[Task[i32]].new()
    tasks.push(fetch_data(1))
    tasks.push(fetch_data(2))
    assert(tasks.len() == 2)

fn test_task_can_be_awaited:
    send_analytics(1).await

fn test_statement_task_detaches:
    send_analytics(2)

fn test_async_method_in_trait:
    let db = RemoteDb { base: 40 }
    let task = db.fetch(2)
    assert(task.await == 42)

fn main:
    test_regular_function_can_call_async()
    test_task_values_can_be_passed_and_stored()
    test_task_can_be_awaited()
    test_statement_task_detaches()
    test_async_method_in_trait()
    print("ok")
