//! expect-check-fail: use of moved value

// #1481 / §12.4: a let-bound closure captures `c` by place; its body returns
// `c`, so each call consumes the originating place. The second call is the
// ordinary use-after-move, reported at the call. A Vec, not a str: a str
// capture is copied (D111).
fn main:
    var c: Vec[i32] = [1]
    let f: fn() -> Vec[i32] = () => c
    print(f().len())
    print(f().len())
