//! expect-stdout: method 2
//! expect-stdout: builtins 2
//! expect-stdout: tan 0
//! expect-stdout: hypot 5
//! expect-stdout: USERFN
//! expect-stdout: call 4242
// #3310: `x.cbrt()` and `builtins.cbrt(x)` are the builtin (§17.6a, §18.2),
// and Sema said so; codegen then looked the C library's `cbrt` up in the
// table of the program's own functions and called the user's `cbrt` with
// the builtin's arguments. The bare call is still the user's function
// (§17.6a: a function of the same name defined in scope takes precedence).
fn cbrt(x: f64) -> f64:
    print("USERFN")
    4242.0

fn tan(x: f64) -> f64: 77.0

fn hypot(a: f64, b: f64) -> f64: 99.0

fn main:
    let h = 8.0
    print(f"method {h.cbrt()}")
    print(f"builtins {builtins.cbrt(8.0)}")
    let z = 0.0
    print(f"tan {z.tan()}")
    let three = 3.0
    print(f"hypot {three.hypot(4.0)}")
    print(f"call {cbrt(h)}")
