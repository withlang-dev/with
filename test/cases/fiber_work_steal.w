// Test: scheduler queue stealing path is exercised
extern fn with_fiber_steal_events() -> i64

async fn make(x: i32) -> i32 =
    x * 2

fn main() -> i32 =
    let t1 = make(1)
    let t2 = make(2)
    let t3 = make(3)
    let t4 = make(4)
    let t5 = make(5)
    let t6 = make(6)

    let sum = t1.await + t2.await + t3.await + t4.await + t5.await + t6.await
    assert(sum == 42)
    assert(with_fiber_steal_events() > 0)
    0
