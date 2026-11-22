//! expect-error: asm template references unknown binding

fn main:
    let r: i64 = unsafe { asm("mov {out}, {nope}" : out("x0") -> i64) }
    print("x")
