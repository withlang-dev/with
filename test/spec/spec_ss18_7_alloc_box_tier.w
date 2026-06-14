//! check-only
//! args: --no-std --alloc

@[global_allocator]
global ALLOC: i32 = 0

@[panic_handler]
fn on_panic -> Never: unreachable()

@[entry]
fn start -> i32:
    let boxed: Box[i32] = Box.new(7)
    let _ = boxed
    0
