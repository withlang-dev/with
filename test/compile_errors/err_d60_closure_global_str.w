//! expect-check-fail: cannot move out of global `name`

// §9.1 / D60 with D52: a closure under `fn() -> str` returns a read of the
// global its body assigns.

var name: str = ""
fn main:
    let f: fn() -> str = () => name = "x".clone()
    print(f())
