//! expect-check-fail: cannot move out of global `name`

// §9.1 / D60 with D52: a closure under `fn() -> List[i32]` returns a read of
// the global its body assigns.
// A List global, not a str: a str global is read by copy (D111).

var name: List[i32] = List.new()
fn main:
    let f: fn() -> List[i32] = () => name = [1]
    print(f().len())
