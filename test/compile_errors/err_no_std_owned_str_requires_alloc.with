//! args: --no-std
//! expect-check-fail: str requires alloc

@[panic_handler]
fn on_panic -> Never: unreachable()

@[entry]
fn start -> i32:
    let owned: str = "hello"
    owned.len()
