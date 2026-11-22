//! expect-stdout: 2
//! expect-stdout: 3
//! expect-stdout: 4

// #1609 (§12.4): a bare fn coerces to an `extern "C" fn` parameter of a
// generic fn or a generic method — the template's parameter type names no
// type parameter, so the argument is checked against it, as through a
// concrete callee.
fn my(x: i32) -> i32: x + 1
fn plain(f: extern "C" fn(i32) -> i32) -> i32: f(1)
fn g2[U](u: U, f: extern "C" fn(i32) -> i32) -> i32: f(2)
type A { z: i32 }
impl A:
    fn reg[U](u: U, f: extern "C" fn(i32) -> i32) -> i32: f(3)
fn main:
    print(f"{plain(my)}")
    print(f"{g2(1, my)}")
    let a = A { z: 0 }
    print(f"{a.reg(1, my)}")
