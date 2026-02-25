// Phase 4 gap: @[no_await_guard] attribute and enforcement not implemented
@[no_await_guard]
type Guard = { v: i32 }

async fn work() -> i32 = 1

fn main() -> i32 =
    let g = Guard { v: 1 }
    let t = work()
    let _ = t.await
    if g.v == 1 then 0 else 1
