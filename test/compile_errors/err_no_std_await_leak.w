//! args: --no-std --alloc
//! expect-check-fail: await requires std/fiber runtime

@[global_allocator]
global ALLOC: i32 = 0

@[panic_handler]
fn on_panic -> Never: unreachable()

async fn worker -> i32: 1

@[entry]
fn start -> i32:
    worker().await
