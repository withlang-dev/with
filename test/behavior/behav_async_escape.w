//! expect-stdout: ok

async fn compute(x: i32) -> i32:
    x * x

fn spawn_task() -> Task[i32]:
    compute(7)

async fn main:
    let t = spawn_task()
    let r = t.await
    assert(r == 49)
    print("ok")
