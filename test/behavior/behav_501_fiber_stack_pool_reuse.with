//! expect-stdout: 2 first 1 new, second 0 new, 1 reused, 1 pooled

// #501 (§14.19): a completed task's stack returns to the pool, and the next
// task takes it from there. Counters only: no timing, no addresses, no
// scheduler order. The first task allocates one stack and leaves it pooled;
// the second allocates none and reuses one.
extern fn with_fiber_pool_allocs() -> i64
extern fn with_fiber_pool_reuses() -> i64
extern fn with_fiber_pool_free_count() -> i32

async fn unit_task() -> i32: 1

async fn main:
    let allocs0 = with_fiber_pool_allocs()
    let reuses0 = with_fiber_pool_reuses()
    let first = unit_task()
    let x = first.await
    let allocs1 = with_fiber_pool_allocs()
    let pooled = with_fiber_pool_free_count()
    let second = unit_task()
    let y = second.await
    let allocs2 = with_fiber_pool_allocs()
    let reuses2 = with_fiber_pool_reuses()
    print(f"{x + y} first {allocs1 - allocs0} new, second {allocs2 - allocs1} new, {reuses2 - reuses0} reused, {pooled} pooled")
