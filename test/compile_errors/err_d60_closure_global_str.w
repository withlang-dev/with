//! expect-check-fail: cannot move out of global `name`

// §9.1 / D60 with D52: a closure under `fn() -> Vec[i32]` returns a read of
// the global its body assigns.
// A Vec global, not a str: a str global is read by copy (D111).

var name: Vec[i32] = Vec.new()
fn main:
    let f: fn() -> Vec[i32] = () => name = [1]
    print(f().len())
