//! args: --no-std
//! expect-check-fail: HashMap requires alloc

@[panic_handler]
fn on_panic -> Never: unreachable()

@[entry]
fn start -> i32:
    let map: HashMap[i32, i32] = HashMap.new()
    map.len()
