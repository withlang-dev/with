//! args: --no-std --alloc
//! expect-check-fail: async fn requires std/fiber runtime

@[global_allocator]
global ALLOC: i32 = 0

@[panic_handler]
fn on_panic -> Never: unreachable()

async fn worker -> i32: 1

@[entry]
fn start -> i32:
    let v: Vec[i32] = Vec.new()
    v.len()
