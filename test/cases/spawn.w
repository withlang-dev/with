// Test: spawn (fire-and-forget async tasks)
async fn work(x: i32) -> i32 =
    x * 10

fn main() -> i32 =
    // Spawn fires off a task but doesn't return a handle
    spawn work(1)
    spawn work(2)
    spawn work(3)

    // Also test spawn alongside await
    let t = work(42)
    let r = t.await
    assert(r == 420)
    0
