//! expect-stdout: ok

// §16.13 {name} placeholder substitution. aarch64 host: x0 output, x1 input.

fn main:
    let a: i64 = 42
    let r: i64 = unsafe { asm("mov {out}, {src}" : out("x0") -> i64 : src("x1") a) }
    if r == 42:
        print("ok")
    else:
        print("bad")
