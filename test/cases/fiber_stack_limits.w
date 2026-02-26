// Test: fixed stack strategy limits and live-fiber accounting
extern fn with_fiber_stack_size_bytes() -> i64
extern fn with_fiber_max_fibers() -> i32
extern fn with_fiber_live_fibers() -> i32

async fn unit(x: i32) -> i32 =
    x

fn main() -> i32 =
    let stack_bytes = with_fiber_stack_size_bytes()
    let max_fibers = with_fiber_max_fibers()
    assert(stack_bytes >= 4096)
    assert(max_fibers >= 64)
    assert(with_fiber_live_fibers() == 0)

    var i: i32 = 0
    var hit_limit = false
    while i < max_fibers + 2:
        let t = unit(i)
        if t == -1:
            hit_limit = true
            break
        let _keep = t
        i += 1

    assert(hit_limit)
    assert(with_fiber_live_fibers() <= max_fibers)
    0
