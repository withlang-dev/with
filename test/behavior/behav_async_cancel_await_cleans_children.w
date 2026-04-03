//! expect-stdout: ok

extern fn with_fiber_live_fibers() -> i32

async fn chain(depth: i32) -> i32:
    if depth <= 0:
        return 7
    let child = chain(depth - 1)
    child.await

async fn fast() -> i32:
    1

async fn main:
    let baseline = with_fiber_live_fibers()
    let slow = chain(32)
    let winner = fast()
    select await:
        x = winner => assert(x == 1)
        y = slow => assert(y == 7)
    assert(with_fiber_live_fibers() == baseline)
    print("ok")
