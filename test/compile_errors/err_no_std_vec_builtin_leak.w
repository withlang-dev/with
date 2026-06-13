//! args: --no-std
//! expect-check-fail: Vec requires alloc

@[panic_handler]
fn on_panic -> Never: unreachable()

@[entry]
fn start -> i32:
    let xs: Vec[i32] = Vec.new()
    xs.len()
