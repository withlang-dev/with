//! expect-check-fail: use of moved value

// #1481 / §12.4: a let-bound closure captures `c` by place; its body returns
// `c`, so each call consumes the originating place. The second call is the
// ordinary use-after-move, reported at the call.
fn main:
    var c = "a".clone()
    let f: fn() -> str = () => c
    print(f())
    print(f())
