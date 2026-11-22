//! args: --no-std
//! expect-check-fail: List requires alloc

@[panic_handler]
fn on_panic -> Never: unreachable()

@[entry]
fn start -> i32:
    let xs: List[i32] = List.new()
    xs.len()
