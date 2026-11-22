//! expect-error: asm requires unsafe context

fn main:
    let r: i64 = asm("mov {out}, {out}" : out("x0") -> i64)
    print("x")
