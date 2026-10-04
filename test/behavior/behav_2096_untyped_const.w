//! expect-stdout: 12 12 12 12
//! expect-stdout: 10 21 10 6
//! expect-stdout: 24 5.25
//! expect-stdout: true true
//! expect-stdout: 250 -3
//! expect-stdout: ok

// D88 (§4.2.1, #2096): a `const` declared without a type, whose initializer
// is made only of unsuffixed numeric literals, operators on them, and other
// such constants, has no numeric type of its own. Each use is typed as the
// initializer would be if written there.

const STEP = 1.0 / 120.0
const SPEED = 12.0
const N = 10
const M = N * 2 + 1
const HALF = SPEED / 2.0
const EDGE = 200 + 50
const DOWN = -3

fn takes32(x: f32) -> f32: x
fn takes64(x: f64) -> f64: x

fn main:
    // The same constant is f32 at one use and f64 at another.
    let a = takes32(SPEED)
    let b: f32 = SPEED
    let c = takes64(SPEED)
    let d = SPEED
    print(f"{a} {b} {c} {d}")
    // An integer constant takes the integer its use demands, or the float;
    // a constant made of constants follows them.
    let e: u8 = N
    let f: u64 = M
    let g: f32 = N
    let h: f32 = HALF
    print(f"{e} {f} {g} {h}")
    // A peer operand decides, and so does arithmetic over the constant.
    var x: f32 = 2.0
    x = x * SPEED
    let q: f32 = M / 4
    print(f"{x} {q}")
    // The initializer is evaluated at the use's type: f32 division here,
    // f64 there, exactly as the literals would be.
    let s32: f32 = STEP
    let s64: f64 = STEP
    let lit32: f32 = 1.0 / 120.0
    let lit64: f64 = 1.0 / 120.0
    print(f"{s32 == lit32} {s64 == lit64}")
    let edge: u8 = EDGE
    let down: i8 = DOWN
    print(f"{edge} {down}")
    print("ok")
