//! expect-stdout: ok

async fn fetch_data(id: i32) -> Result[i32, str]:
    id + 1

async fn maybe_config(id: i32) -> Result[i32, str]:
    id + 1

async fn load_config(id: i32) -> Result[i32, str]:
    let base = maybe_config(id).await?
    base + 1

async fn read_ref_after_await(value: &i32) -> i32:
    let before = *value
    let _ = fetch_data(0).await
    before + *value

fn await_from_regular_function -> i32:
    fetch_data(41).await.unwrap()

fn parallel_tuple_await -> i32:
    let left_task = fetch_data(10)
    let right_task = fetch_data(20)
    let (left, right) = (left_task, right_task).await
    left.unwrap() + right.unwrap()

fn task_is_storable:
    var tasks = Vec[Task[Result[i32, str]]].new()
    tasks.push(fetch_data(1))
    tasks.push(fetch_data(2))
    assert(tasks.len() == 2)

async fn scoped_tracking:
    async scope s =>:
        s.track(fetch_data(3))
        s.track(fetch_data(4))

fn references_survive_await -> i32:
    let value = 21
    read_ref_after_await(&value).await

fn main:
    assert(await_from_regular_function() == 42)
    assert(parallel_tuple_await() == 32)
    assert(load_config(40).await.unwrap() == 42)
    assert(references_survive_await() == 42)
    scoped_tracking().await
    task_is_storable()
    print("ok")
