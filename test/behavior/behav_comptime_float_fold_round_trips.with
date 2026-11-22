//! expect-stdout: true true true true
//! expect-stdout: ok

// A float constant folded at compile time is the value its initializer has:
// the fold wrote it back with 17 digits after the decimal point, which for a
// small value is fewer than the 17 significant digits a double needs, so
// `const STEP: f64 = 1.0 / 120.0` was not equal to `1.0 / 120.0`.

const STEP: f64 = 1.0 / 120.0
const TINY: f64 = 1.0 / 3000000000.0
const THIRD: f64 = 1.0 / 3.0
const BIG: f64 = 123456789.0 * 1000000.0 / 7.0

fn quotient(a: f64, b: f64) -> f64: a / b

fn main:
    print(f"{STEP == quotient(1.0, 120.0)} {TINY == quotient(1.0, 3000000000.0)} {THIRD == quotient(1.0, 3.0)} {BIG == quotient(123456789.0 * 1000000.0, 7.0)}")
    print("ok")
