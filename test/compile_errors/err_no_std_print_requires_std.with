//! args: --no-std
//! expect-check-fail: print requires std

@[panic_handler]
fn on_panic -> Never: unreachable()

@[entry]
fn start -> i32:
    print("hello")
    0
