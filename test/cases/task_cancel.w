// Test: Task.cancel() basic behavior
async fn work -> i32: 1

fn main -> i32:
    let t = work()
    t.cancel()
    0
