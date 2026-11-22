//! expect-check-fail: cannot move out of global `name`

// §9.1 / D60 with D52: a closure under `fn() -> List[Tok]` returns a read of
// the global its body assigns.
// A List global, not a str: a str global is read by copy (D111).

type Tok { id: i32 }
impl Drop for Tok:
    move fn drop(): {}
var name: List[Tok] = List.new()
fn main:
    let f: fn() -> List[Tok] = () => name = [Tok { id: 1 }]
    print(f().len())
