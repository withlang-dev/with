//! env: WITH_CODEGEN_UNITS=8
//! expect-stdout: x
//! expect-stdout: shown
//! expect-stdout: 376
//! expect-stderr: x

// #681 codegen units: a generic instance's MIR body is packed into one unit,
// but its LLVM body was only generated on demand, by a call in the current
// unit. When every caller sat in another unit, the owner never defined the
// instance, the caller's unit demoted its own copy, and the link came up
// undefined (`_print__sema__..=16` referenced from the caller's unit,
// defined by none). Eight units over these bodies reproduced it, for the
// prelude's generic `print` and for a program's own generic alike.

fn big(n: i32) -> i32:
    var acc = 0
    for i in 0..n:
        acc = acc + i * 3
        if acc % 7 == 0: acc = acc - 1
        if acc % 11 == 0: acc = acc + 2
        if acc % 13 == 0: acc = acc + 5
    acc

fn t1() -> i32: big(3)
fn t2() -> i32: big(5)
fn t3() -> i32: big(7)
fn t4() -> i32: big(9)
fn t5() -> i32: big(11)

fn show[T](v: &T): print("shown")

fn caller() -> Unit:
    let s: str = "x"
    print(s)
    eprint(s)
    show(s)

fn main:
    caller()
    print(f"{t1() + t2() + t3() + t4() + t5()}")
