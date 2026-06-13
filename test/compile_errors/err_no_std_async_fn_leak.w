//! args: --no-std
//! expect-check-fail: async fn requires std/fiber runtime

@[panic_handler]
fn on_panic -> Never: unreachable()

async fn worker -> i32: 1

@[entry]
fn start -> i32:
    0
