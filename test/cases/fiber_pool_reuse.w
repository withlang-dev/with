// Test: fiber pool/stack reuse across sequential async tasks
extern fn with_fiber_pool_reuses() -> i64
extern fn with_fiber_pool_allocs() -> i64

async fn bump(x: i32) -> i32:
    x + 1

fn main -> i32:
    let t1 = bump(1)
    assert(t1.await == 2)
    let allocs_after_first = with_fiber_pool_allocs()
    assert(allocs_after_first >= 1)

    let t2 = bump(2)
    assert(t2.await == 3)
    let reuses = with_fiber_pool_reuses()
    let allocs_after_second = with_fiber_pool_allocs()
    assert(reuses >= 1)
    assert(allocs_after_second == allocs_after_first)
