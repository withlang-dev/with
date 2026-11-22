//! expect-stdout: 0.05
//! expect-stdout: 7.5
//! expect-stdout: 7
//! expect-stdout: 4e+09
//! expect-stdout: -3
//! expect-stdout: true
//! expect-stdout: 2.5
//! expect-stdout: ok

// D181 (§4.2.6): an integer beside a float is the float. `i / 140.0` is
// f64; an integer where a float is demanded converts as `as` would, with
// its own signedness (a u32 above 2^31 stays positive); a comparison of an
// integer with a float compares as floats. Before, each needed `as f64`,
// which stated what the compiler knew (#1803 pinned the refusal).

fn half(x: f64): x / 2.0

fn main:
    let i: isize = 7
    let p = i / 140.0
    print(f"{p}")
    let j: i32 = 3
    print(f"{j * 2.5}")
    let a: [2]f64 = [0.0, j + 4]
    print(f"{a[1]}")
    let u: u32 = 4000000000
    let big: f64 = u
    print(f"{big}")
    let s: i32 = -3
    let f: f32 = s
    print(f"{f}")
    print(f"{j < 3.5}")
    print(f"{half(5)}")
    print("ok")
