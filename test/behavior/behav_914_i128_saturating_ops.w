//! expect-stdout: ok

// #914: saturating arithmetic at 128 bits, via the explicit operators
// (§4.2.3), which share the saturate overflow mode's lowering. Codegen
// mangled the intrinsic as llvm.uadd.sat.i64 for any width past 32 and
// widened an i128 multiply to i128 with 64-bit clamp bounds, so any
// saturating i128/u128 operation emitted invalid IR.
fn addsat(a: i128, b: i128) -> i128: a +| b
fn subsat(a: i128, b: i128) -> i128: a -| b
fn mulsat(a: i128, b: i128) -> i128: a *| b
fn addsatu(a: u128, b: u128) -> u128: a +| b
fn subsatu(a: u128, b: u128) -> u128: a -| b
fn mulsatu(a: u128, b: u128) -> u128: a *| b

fn main:
    let max: i128 = 170141183460469231731687303715884105727
    let min: i128 = -170141183460469231731687303715884105728
    let umax: u128 = 340282366920938463463374607431768211455
    assert(addsat(max, 5) == max)
    assert(subsat(min, 5) == min)
    assert(addsatu(umax, 5) == umax)
    assert(subsatu(0, 5) == 0)
    let pow100: i128 = 1267650600228229401496703205376
    let pow50: i128 = 1125899906842624
    assert(mulsat(pow100, pow50) == max)
    assert(mulsat(0 - pow100, pow50) == min)
    assert(mulsatu(umax, 2) == umax)
    // In-range results are exact, not clamped.
    assert(addsat(pow100, 5) == pow100 + 5)
    assert(mulsat(pow50, pow50) == pow100)
    print("ok")
