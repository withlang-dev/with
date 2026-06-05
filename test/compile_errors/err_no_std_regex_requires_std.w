//! args: --no-std
//! expect-check-fail: regex literals require std

@[panic_handler]
fn on_panic -> Never: unreachable()

@[entry]
fn start -> i32:
    let _ = /abc/
    0
