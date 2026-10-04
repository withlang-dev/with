//! expect-stdout: hello
//! expect-stdout: 8
//! expect-stdout: 2
//! expect-stdout: true
//! expect-stdout: 0

// §18.2 (#1930): every prelude function and every compiler intrinsic callable
// by a bare name is also reachable as `builtins.name`, without a `use` —
// including where this module declares the bare name itself.

fn sqrt(x: f64) -> f64: x + 100.0

fn main:
    builtins.print("hello")
    print(f"{builtins.sizeof[i64]()}")
    print(f"{builtins.sqrt(4.0) as i32}")
    print(f"{builtins.src().len() > 0}")
    builtins.assert(true)
    print(f"{builtins.sin(0.0) as i32}")
