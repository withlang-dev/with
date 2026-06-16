//! expect-stdout: ok

// §16.13 multiple outputs surface as a tuple. aarch64 host.

fn main:
    let v: i64 = 7
    let (lo, hi) = unsafe { asm("mov {o1}, {a}\nmov {o2}, {a}" : o1("x9") -> i64, o2("x10") -> i64 : a("x11") v) }
    if lo == 7 and hi == 7:
        print("ok")
    else:
        print("bad")
