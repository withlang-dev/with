//! expect-check-fail: use of moved value

// #1481 / §12.4: a let-bound closure captures `c` by place; its body returns
// `c`, so each call consumes the originating place. The second call is the
// ordinary use-after-move, reported at the call. A List, not a str: a str
// capture is copied (D111).
type Tok { id: i32 }
impl Drop for Tok:
    move fn drop(): {}
fn main:
    var c: List[Tok] = [Tok { id: 1 }]
    let f: fn() -> List[Tok] = () => c
    print(f().len())
    print(f().len())
