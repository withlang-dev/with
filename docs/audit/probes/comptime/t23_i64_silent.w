// T23 probe: cross-check open issue #943 (silent i64 truncation in comptime arith).
comptime fn ident() -> i64:
    3000000001i64 + 0i64

const I: i64 = comptime ident()

fn main:
    print(f"{I}")
