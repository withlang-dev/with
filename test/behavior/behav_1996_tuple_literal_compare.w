//! expect-stdout: true false true
//! expect-stdout: true true
//! expect-stdout: true false

// #1996 (§4.2.1 rule 3): a tuple or array literal beside a typed operand
// takes that operand's type, as a bare literal does in `x == 1`. Before,
// `u == (1, 2)` with `u: (i8, i64)` typed the literal `(i32, i32)`, Sema
// accepted the pair, and MIR validation refused it ("comparison operands
// have incompatible MIR types", after a stray `DEBUG cmp fail:` line).

fn main:
    let u: (i8, i64) = (1, 2)
    print(f"{u == (1, 2)} {u == (1, 3)} {(1, 2) == u}")
    let w: (u8, (i16, i64)) = (7, (-3, 9))
    print(f"{w == (7, (-3, 9))} {(7, (-3, 9)) == w}")
    let a: [u8; 3] = [1, 2, 3]
    print(f"{a == [1, 2, 3]} {[1, 2, 4] == a}")
