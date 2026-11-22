//! expect-stdout: ok
//! only-on: aarch64
// §16: an asm block's 4th section lists clobbered registers.
fn main:
    let v: i64 = 21
    let r: i64 = unsafe { asm("mov x10, {a}\nmov {o}, x10" : o("x9") -> i64 : a("x11") v : "x10") }
    if r == 21: print("ok")
    else: print("bad")
